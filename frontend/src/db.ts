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

cacheGenres();

async function cacheGenres() {
	const rows = await sql`SELECT id::bigint, name FROM genres`;
	for (const row of rows) {
		genres[row.id] = row.name;
		sortedGenres.push({ id: row.id, name: row.name });
	}
	sortedGenres.sort((a, b) => Number(a.name < b.name));
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
		FROM titles
		WHERE ts IS NOT NULL
		AND language = 'en'
		AND type = ${type}
		AND rating >= 'PG-13'
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	` as unknown as Title[];

	cacheTitles(trending);

	return trending;
}

export async function getTopRated(type: "movie" | "tv"): Promise<Title[]> {
	const topRated = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating
		FROM titles
		WHERE ts IS NOT NULL
		AND language = 'en'
		AND type = ${type}
		AND votes >= 1000
		ORDER BY score DESC NULLS LAST
		LIMIT 100
	` as unknown as Title[];

	cacheTitles(topRated);

	return topRated;
}

export async function getTitlesWithGenre(type: "movie" | "tv", genre: number): Promise<Title[]> {
	const titles = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating
		FROM titles
		WHERE ts IS NOT NULL
		AND language = 'en'
		AND type = ${type}
		AND ${genre} = ANY(genres)
		AND rating >= 'PG-13'
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	` as unknown as Title[];

	cacheTitles(titles);

	return titles;
}

let autocompleteQuery: null | postgres.PendingQueryModifiers<postgres.Row[]> = null;
export async function getAutocomplete(query: string): Promise<null | Title[]> {
	autocompleteQuery?.cancel();
	autocompleteQuery = sql`
		SELECT id, type, title, genres, overview, released, trailer, rating
		FROM titles
		WHERE ts IS NOT NULL
		AND title ILIKE ${"%" + query.split(" ").join("%") + "%"}
		ORDER BY popularity DESC NULLS LAST
		LIMIT 2
	`.execute();
	let titles;
	try {
		titles = await autocompleteQuery as unknown as Title[];
	} catch (err) {
		console.error(err);
		return null;
	}

	cacheTitles(titles);

	return titles;
}
