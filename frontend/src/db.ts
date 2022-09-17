import postgres from "postgres";
import { error } from "./log";

interface Genre {
	id: number,
	name: string,
}

export interface Title {
	id: number,
	title: string,
	genres: number[],
	overview: string,
	released: string,
	trailer: string | null,
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
		cache[title.id] = title;
		title.poster = new Image();
		title.poster.className = "rounded-md";
		title.poster.addEventListener("error", (err) => {
			error("failed to load poster: %O", err);
		});
		title.poster.src = `file://${process.env.POSTERS_PATH}/movie/${title.id}`;
	}
}

export const genres: { [id: number]: string } = {};

export const cache: { [id: number]: Title } = {};

export const sortedGenres: Genre[] = [];

export async function getTrending(type: "movies"): Promise<Title[]> {
	const trending = await sql`
		SELECT id, title, genres, overview, released::text, trailer
		FROM titles
		WHERE movie = ${type === "movies"}
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	` as unknown as Title[];

	cacheTitles(trending);

	return trending;
}

export async function getTopRated(type: "movies"): Promise<Title[]> {
	const topRated = await sql`
		SELECT id, title, genres, overview, released::text, trailer
		FROM titles
		WHERE movie = ${type === "movies"}
		AND votes >= 1000
		ORDER BY score DESC NULLS LAST
		LIMIT 100
	` as unknown as Title[];

	cacheTitles(topRated);

	return topRated;
}

export async function getTitlesWithGenre(type: "movies", genre: number): Promise<Title[]> {
	const titles = await sql`
		SELECT id, title, genres, overview, released::text, trailer
		FROM titles
		WHERE movie = ${type === "movies"}
		AND ${genre} = ANY(genres)
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
		SELECT id, title, genres, overview, released::text, trailer
		FROM titles
		WHERE overview IS NOT NULL
		AND title ILIKE ${"%" + query.split(" ").join("%") + "%"}
		ORDER BY popularity DESC NULLS LAST
		LIMIT 2
	`.execute();
	let titles;
	try {
		titles = await autocompleteQuery as unknown as Title[];
	} catch (_) {
		return null;
	}

	cacheTitles(titles);

	return titles;
}
