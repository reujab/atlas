import getGenres, { expandGenres } from "./genres";
import sql from "./sql";

export interface Row {
	name: string;
	titles: any[];
}

export default async function getRows(type: "movie" | "tv"): Promise<Row[]> {
	return (await Promise.all([
		getTrending(type),
		getTopRated(type),
		getGenres(type),
	])).flat();
}

async function getTrending(type: "movie" | "tv"): Promise<Row[]> {
	const titles = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating, poster
		FROM titles
		WHERE type = ${type}
		AND language = 'en'
		AND rating >= 'PG-13'
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	`;
	expandGenres(titles);
	return [{
		name: "Trending",
		titles,
	}];
}

async function getTopRated(type: "movie" | "tv"): Promise<Row[]> {
	const titles = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating, poster
		FROM titles
		WHERE type = ${type}
		AND votes >= 1000
		AND language = 'en'
		ORDER BY score DESC NULLS LAST, popularity DESC NULLS LAST
		LIMIT 100
	`;
	expandGenres(titles);
	return [{
		name: "Top rated",
		titles,
	}];
}
