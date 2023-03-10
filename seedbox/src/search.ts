import express from "express";
import sql from "./sql";

export default async function search(req: express.Request, res: express.Response): void {
	const query = req.query.q as string;

	if (!query || !/[a-z0-9 ]/.test(query)) {
		res.status(400).end();
		return;
	}

	const titles = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating, poster
		FROM titles
		WHERE title ILIKE ${`%${query.replace(/\s/g, "%")}%`}
		-- AND NOT id = ANY({blacklist})
		ORDER BY popularity DESC NULLS LAST
		LIMIT 2
	`;

	res.json(titles);
}
