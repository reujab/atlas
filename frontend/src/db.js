const postgres = require("postgres");

const sql = postgres({
	database: "pi-es",
	username: "reujab",
});
let trending, topRated;

getGenres();
getTrending();
getTopRated();

async function getGenres() {
	const rows = await sql`SELECT id::bigint, name FROM genres`;
	for (const row of rows) {
		genres[row.id] = row.name;
	}
}

export const cache = {};

export const genres = {};

export async function getTrending() {
	if (!trending) {
		trending = await sql`
			SELECT id, title, genres, overview, released::text FROM movies
			ORDER BY popularity DESC NULLS LAST
			LIMIT 100
		`;

		for (const title of trending) {
			cache[title.id] = title;
		}
	}

	return trending;
}

export async function getTopRated() {
	if (!topRated) {
		topRated = await sql`
			SELECT id, title, genres, overview, released::text FROM movies
			WHERE votes >= 1000
			ORDER BY score DESC NULLS LAST
			LIMIT 200
		`;

		for (const title of topRated) {
			cache[title.id] = title;
		}
	}

	return topRated;
}
