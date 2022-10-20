import postgres from "postgres";
import { error } from "./log";

interface Genre {
	id: number,
	name: string,
}

export interface Title {
	type: "movie" | "tv",
	id: number,
	title: string,
	genres: number[],
	overview: string,
	released: Date,
	trailer: string | null,
	rating: null | string,
	poster: HTMLImageElement,
}

const sql = postgres({
	database: "atlas",
	username: "atlas",
});

export async function cacheGenres() {
	const rows = await sql`SELECT id::bigint, name FROM genres`;
	for (const row of rows) {
		genres[row.id] = row.name;
		sortedGenres.push({ id: row.id, name: row.name });
	}
	sortedGenres.sort((a, b) => a.name.localeCompare(b.name));
}

function cacheTitles(titles: Title[]) {
	for (const title of titles) {
		cache[title.type][title.id] = title;
		title.poster = new Image();
		title.poster.className = "rounded-md";
		title.poster.addEventListener("error", (err) => {
			error("failed to load poster: %O", err);
		});
		title.poster.src = `file://${process.env.POSTERS_PATH}/${title.type}/${title.id}`;
	}
}

export const genres: { [id: number]: string } = {};

export const cache: { [type: string]: { [id: number]: Title } } = {
	movie: {},
	tv: {},
};

export const sortedGenres: Genre[] = [];

export async function getTrending(type: "movie" | "tv"): Promise<Title[]> {
	const trending = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating
		FROM (
			SELECT * from titles
			WHERE type = ${type}
			ORDER BY popularity DESC NULLS LAST
			LIMIT 200
		) AS titles
		WHERE ts IS NOT NULL
		AND language = 'en'
		AND rating >= 'PG-13'
		LIMIT 100
	` as unknown as Title[];

	cacheTitles(trending);

	return trending;
}

export async function getTopRated(type: "movie" | "tv"): Promise<Title[]> {
	const topRated = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating
		FROM (
			SELECT * FROM titles
			WHERE type = ${type}
			AND votes >= 1000
			ORDER BY score DESC NULLS LAST, popularity DESC NULLS LAST
			LIMIT 200
		) AS titles
		WHERE ts IS NOT NULL
		AND language = 'en'
		LIMIT 100
	` as unknown as Title[];

	cacheTitles(topRated);

	return topRated;
}

export async function getTitlesWithGenre(type: "movie" | "tv", genre: number): Promise<Title[]> {
	let titles;
	if (genre === sortedGenres.find((genre) => genre.name === "Kids").id) {
		titles = await sql`
			SELECT id, type, title, genres, overview, released, trailer, rating
			FROM (
				SELECT * FROM titles
				WHERE type = ${type}
				AND rating < 'PG-13'
				ORDER BY popularity DESC NULLS LAST
				LIMIT 200
			) AS titles
			WHERE ts IS NOT NULL
			AND language = 'en'
			LIMIT 100
		` as unknown as Title[];
	} else {
		titles = await sql`
			SELECT id, type, title, genres, overview, released, trailer, rating
			FROM (
				SELECT * FROM titles
				WHERE type = ${type}
				AND ${genre} = ANY(genres)
				AND (rating >= 'PG-13' OR ${genre} = 99)
				ORDER BY popularity DESC NULLS LAST
				LIMIT 200
			) AS titles
			WHERE ts IS NOT NULL
			AND language = 'en'
			LIMIT 100
		` as unknown as Title[];
	}

	cacheTitles(titles);

	return titles;
}

let autocompleteQuery: null | postgres.PendingQueryModifiers<postgres.Row[]> = null;
export const autocompleteCache: { [query: string]: Title[] } = {};
export async function getAutocomplete(query: string): Promise<null | Title[]> {
	autocompleteQuery?.cancel();

	if (autocompleteCache[query]) {
		return autocompleteCache[query];
	}

	// remove old search results
	const blacklist = new Set();
	for (let i = 1; i < query.length - 1; i++) {
		for (const title of autocompleteCache[query.slice(0, i)]) {
			blacklist.add(title.id);
		}
	}

	autocompleteQuery = sql`
		SELECT id, type, title, genres, overview, released, trailer, rating
		FROM (
			SELECT * FROM titles
			WHERE title ILIKE ${"%" + query.replace(/\s/g, "%") + "%"}
			ORDER BY popularity DESC NULLS LAST
			LIMIT 100
		) AS titles
		WHERE ts IS NOT NULL
		AND NOT id = ANY(${[...blacklist] as number[]})
		LIMIT 2
	`.execute();
	let titles;
	try {
		titles = await autocompleteQuery as unknown as Title[];
	} catch (err) {
		console.error(err);
		return null;
	}

	autocompleteCache[query] = titles;
	cacheTitles(titles);

	return titles;
}
