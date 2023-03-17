import express from "express";
import sql from "./sql";

const genreMap: { [id: number]: string } = {};
const sortedGenres: Genre[] = [];

interface Genre {
	id: number;
	name: string;
}

(async () => {
	const rows = await sql`SELECT id::bigint, name FROM genres`;
	for (const row of rows) {
		genreMap[row.id] = row.name;
		sortedGenres.push({ id: row.id, name: row.name });
	}
	sortedGenres.sort((a, b) => a.name.localeCompare(b.name));
})();

export default async function getGenres(req: express.Request, res: express.Response): Promise<void> {
	const genres: any[] = [];

	await Promise.all(sortedGenres.map(async (genre) => {
		if (genre.name === "Family") return;

		const row = {
			genre: genre.name,
			titles: [],
		};

		genres.push(row);

		if (genre.name === "Kids") {
			row.titles = await sql`
				SELECT id, type, title, genres, overview, released, trailer, rating, poster
				FROM titles
				WHERE type = ${req.params.type}
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
					WHERE type = ${req.params.type}
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
	res.json(genres.filter((g) => g.titles.length));
}

export function expandGenres(titles: any[]): void {
	for (const title of titles) {
		title.genres = title.genres.map((g: any) => genreMap[g]);
	}
}
