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

export default async function getGenres(type: "movie" | "tv"): Promise<Row[]> {
	const rows: Row[] = [];

	await Promise.all(sortedGenres.map(async (genre) => {
		if (genre.name === "Family") return;

		const row = {
			name: genre.name,
			titles: [],
		};

		rows.push(row);

		if (genre.name === "Kids") {
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
				FROM (
					SELECT * FROM titles
					WHERE type = ${type}
					AND ${genre.id} = ANY(genres)
					ORDER BY popularity DESC NULLS LAST
					LIMIT 300
				) AS titles
				WHERE (rating >= 'PG-13' OR ${genre.id} = 99)
				AND language = 'en'
				LIMIT 100
			`;
		}
		expandGenres(row.titles);
	}));

	return rows.filter((g) => g.titles.length >= 20);
}

/// Replaces the genre ids with names.
export function expandGenres(titles: any[]): void {
	for (const title of titles) {
		title.genres = title.genres.map((g: any) => genreMap[g]);
	}
}
