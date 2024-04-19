import { expandGenres } from "./genres";
import sql from "./sql";

export default async function searchTitles(query: string, blacklist: string[]): Promise<any[]> {
	const titles = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating, poster
		FROM titles
		WHERE ts IS NOT NULL
		AND title ILIKE ${`%${query.replace(/\s/g, "%")}%`}
		AND NOT id = ANY(${blacklist})
		ORDER BY popularity DESC NULLS LAST
		LIMIT 5
	`;
	expandGenres(titles);
	return titles;
}
