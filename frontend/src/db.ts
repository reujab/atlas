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

function cachePoster(title: Title) {
	title.poster = new Image();
	title.poster.addEventListener("error", (err) => {
		error("failed to load poster: %O", err);
	});
	title.poster.src = `file://${process.env.POSTERS_PATH}/movie/${title.id}`;
}

export const genres: { [id: number]: string } = {};

export const cache: { [id: number]: Title } = {};

export const sortedGenres: Genre[] = [];

export async function getTrending(type: "movies"): Promise<Title[]> {
	const trending = await sql`
			SELECT id, title, genres, overview, released::text FROM titles
			WHERE movie = ${type === "movies"}
			ORDER BY popularity DESC NULLS LAST
			LIMIT 100
		` as unknown as Title[];

	for (const title of trending) {
		cache[title.id] = title;
		cachePoster(title);
	}

	return trending;
}

export async function getTopRated(type: "movies"): Promise<Title[]> {
	const topRated = await sql`
		SELECT id, title, genres, overview, released::text FROM titles
		WHERE movie = ${type === "movies"}
		AND votes >= 1000
		ORDER BY score DESC NULLS LAST
		LIMIT 100
	` as unknown as Title[];

	for (const title of topRated) {
		cache[title.id] = title;
		cachePoster(title);
	}

	return topRated;
}

export async function getTitlesWithGenre(type: "movies", genre: number): Promise<Title[]> {
	const titles = await sql`
		SELECT id, title, genres, overview, released::text
		FROM titles
		WHERE movie = ${type === "movies"}
		AND ${genre} = ANY(genres)
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	` as unknown as Title[];

	for (const title of titles) {
		cache[title.id] = title as Title;
		cachePoster(title);
	}

	return titles;
}
