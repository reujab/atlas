import Database from "tauri-plugin-sql-api";
import { invoke } from "@tauri-apps/api";

let db, trending, topRated;

invoke("get_db_url").then((db_url) => {
	Database.load(db_url).then((database) => {
		db = database;
		getGenres();
		getTrending();
		getTopRated();
	});
});

async function getGenres() {
	const rows = await db.select(`SELECT id::bigint, name FROM genres`);
	for (const row of rows) {
		genres[row.id] = row.name;
	}
}

export const cache = {};

export const genres = {};

export async function getTrending() {
	if (!trending) {
		trending = await db.select(`
			SELECT id::bigint, title, array_to_string(genres, ',') as genres, overview, released::text FROM movies
			ORDER BY popularity DESC NULLS LAST
			LIMIT 100
		`);

		for (const title of trending) {
			title.genres = title.genres?.split(",").map(Number);
			cache[title.id] = title;
		}
	}

	return trending;
}

export async function getTopRated() {
	if (!topRated) {
		topRated = await db.select(`
			SELECT id::bigint, title, array_to_string(genres, ',') as genres, overview, released::text FROM movies
			WHERE votes >= 1000
			ORDER BY score DESC NULLS LAST
			LIMIT 100
		`);

		for (const title of topRated) {
			title.genres = title.genres?.split(",").map(Number);
			cache[title.id] = title;
		}
	}

	return topRated;
}
