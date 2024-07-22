import { Row } from "./rows";
import sql from "./sql";

interface Genre {
	id: number;
	name: string;
}

const genreMap: { [id: number]: string } = {};
const sortedGenres: Genre[] = [];
(async () => {
	const rows = await sql`SELECT id::bigint, name FROM genres`;
	for (const row of rows) {
		genreMap[row.id] = row.name;
		sortedGenres.push({ id: row.id, name: row.name });
	}
	sortedGenres.sort((a, b) => a.name.localeCompare(b.name));
})();

/**
 * Returns the most popular movies for each genre.
 * The "Kids" genre will only show titles rated less than PG-13.
 * The "Documentaries" genre will show titles with any rating.
 * Every other genre will show titles that are PG-13+.
 * Genres with fewer than 20 titles will be filtered out.
*/
export default async function getGenreRows(type: "movie" | "tv"): Promise<Row[]> {
	const rows: Row[] = [];

	await Promise.all(sortedGenres.map(async (genre) => {
		if (genre.name === "Family") return;

		const row = {
			name: genre.name,
			titles: [],
		};
		rows.push(row);

		if (genre.name === "Kids") {
			// Replace the "Kids" genre with every title rated less than PG-13.
			row.titles = await sql`
				SELECT id, type, title, genres, overview, released, trailer, rating, poster
				FROM titles
				WHERE type = ${type}
				AND language = 'en'
				AND rating < 'PG-13'
				ORDER BY popularity DESC NULLS LAST
				LIMIT 100
			`;
		} else {
			row.titles = await sql`
				SELECT id, type, title, genres, overview, released, trailer, rating, poster
				FROM titles
				WHERE type = ${type}
				AND language = 'en'
				AND ${genre.id} = ANY(genres)
				-- For documentaries, show titles with any rating.
				AND (rating >= 'PG-13' OR ${genre.id} = 99)
				ORDER BY popularity DESC NULLS LAST
				LIMIT 100
			`;
		}
		expandGenres(row.titles);
	}));

	return rows.filter((g) => g.titles.length >= 20);
}

/** Replaces the genre ids with names. */
export function expandGenres(titles: any[]): void {
	for (const title of titles) {
		title.genres = title.genres.map((g: any) => genreMap[g]);
	}
}
