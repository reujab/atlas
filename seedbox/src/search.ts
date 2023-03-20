import express from "express";
import sql from "./sql";
import { expandGenres } from "./genres";

export default async function search(req: express.Request, res: express.Response): Promise<void> {
	const query = req.query.q as string;
	const blacklist = req.query.blacklist ? String(req.query.blacklist).split(",") : [];

	if (!query || !/[a-zA-Z0-9 ]/.test(query)) {
		res.status(400).end();
		return;
	}

	const titles = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating, poster
		FROM titles
		WHERE ts IS NOT NULL
		AND title ILIKE ${`%${query.replace(/\s/g, "%")}%`}
		AND NOT id = ANY(${blacklist})
		ORDER BY popularity DESC NULLS LAST
		LIMIT 4
	`;

	expandGenres(titles);
	res.json(titles);
}
