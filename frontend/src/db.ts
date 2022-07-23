import postgres from "postgres";

type GenreID = number;

interface Genre {
	id: GenreID,
	name: string,
}

interface Title {
	id: number,
	title: string,
	genres: GenreID[],
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
	database: "pi-es",
	username: "reujab",
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

export const genres: { [id: GenreID]: string } = {};

export const cache: { [id: number]: Title } = {};

export const sortedGenres: Genre[] = [];

export async function getTrending(table: "movies"): Promise<Title[]> {
	if (!precache[table].trending) {
		precache[table].trending = await sql`
			SELECT id, title, genres, overview, released::text FROM ${table}
			ORDER BY popularity DESC NULLS LAST
			LIMIT 100
		` as unknown as Title[];

		for (const title of precache[table].trending) {
			cache[title.id] = title;
		}
	}

	return precache[table].trending;
}

export async function getTopRated(table: "movies"): Promise<Title[]> {
	if (!precache[table].topRated) {
		precache[table].topRated = await sql`
			SELECT id, title, genres, overview, released::text FROM ${table}
			WHERE votes >= 1000
			ORDER BY score DESC NULLS LAST
			LIMIT 200
		` as unknown as Title[];

		for (const title of precache[table].topRated) {
			cache[title.id] = title;
		}
	}

	return precache[table].topRated;
}

export async function getTitlesWithGenre(table: string, genre: GenreID): Promise<Title[]> {
	const rows = await sql`
		SELECT id, title, genres, overview, released::text
		FROM ${table}
		WHERE ${genre} = ANY(genres)
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	`;

	for (const title of rows) {
		cache[title.id] = title as Title;
	}

	return rows as unknown as Title[];
}
