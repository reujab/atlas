import postgres from "postgres";

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
}

interface PreCache {
	movies: Queries,
}

interface Queries {
	trending: Title[],
	topRated: Title[],
}

const precache: PreCache = {
	movies: {
		trending: [],
		topRated: [],
	},
};

const sql = postgres({
	database: "atlas",
	username: "atlas",
});

cacheGenres();
getTrending("movies");
getTopRated("movies");

async function cacheGenres() {
	const rows = await sql`SELECT id::bigint, name FROM genres`;
	for (const row of rows) {
		genres[row.id] = row.name;
		sortedGenres.push({ id: row.id, name: row.name });
	}
	sortedGenres.sort((a, b) => Number(a.name < b.name));
}

export const genres: { [id: number]: string } = {};

export const cache: { [id: number]: Title } = {};

export const sortedGenres: Genre[] = [];

export async function getTrending(type: "movies"): Promise<Title[]> {
	if (!precache[type].trending.length) {
		precache[type].trending = await sql`
			SELECT id, title, genres, overview, released::text FROM titles
			WHERE movie = ${type === "movies"}
			ORDER BY popularity DESC NULLS LAST
			LIMIT 100
		` as unknown as Title[];

		for (const title of precache[type].trending) {
			cache[title.id] = title;
		}
	}

	return precache[type].trending;
}

export async function getTopRated(type: "movies"): Promise<Title[]> {
	if (!precache[type].topRated.length) {
		precache[type].topRated = await sql`
			SELECT id, title, genres, overview, released::text FROM titles
			WHERE movie = ${type === "movies"}
			AND votes >= 1000
			ORDER BY score DESC NULLS LAST
			LIMIT 200
		` as unknown as Title[];

		for (const title of precache[type].topRated) {
			cache[title.id] = title;
		}
	}

	return precache[type].topRated;
}

export async function getTitlesWithGenre(type: "movies", genre: number): Promise<Title[]> {
	const rows = await sql`
		SELECT id, title, genres, overview, released::text
		FROM titles
		WHERE movie = ${type === "movies"}
		AND ${genre} = ANY(genres)
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	`;

	for (const title of rows) {
		cache[title.id] = title as Title;
	}

	return rows as unknown as Title[];
}
