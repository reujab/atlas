import { Request, Response } from "express";
import sql from "../sql";
import aliases from "./aliases";
import searchMagnets from "./search";

/**
 * Searches the web for a magnet that best fits the query and returns its UUID.
 * Caches UUID for 24 hours.
 * */
export default async function getUUID(req: Request, res: Response): Promise<void> {
	const type = req.params.type as "movie" | "tv";
	const query = req.params.query;
	const season = req.query.s ? Number(req.query.s) : null;
	const episode = req.query.e ? Number(req.query.e) : null;

	if (type === "tv" && (!season || !episode)) {
		res.status(400).end();
		return;
	}

	await sql`
		DELETE FROM magnets
		WHERE ts < NOW() - INTERVAL '1 day'
	`;
	const existingRow = await sql`
		UPDATE magnets
		SET ts = NOW()
		WHERE query = ${query}
		AND (seasons IS NULL OR ${season} = ANY(seasons))
		AND (episode IS NULL OR episode = ${episode})
		RETURNING uuid, seasons, episode
	`;
	if (existingRow[0]) {
		console.log("Serving existing UUID");
		res.json({
			uuid: existingRow[0].uuid,
			seasons: existingRow[0].seasons,
			episode: existingRow[0].episode,
		});
		return;
	}

	const queries = [query];
	for (const alias of aliases) {
		if (alias.regex.test(query)) {
			if (!alias.add) queries.splice(0, queries.length);
			queries.push(query.replace(alias.regex, alias.replace));
		}
	}

	const searches = [];
	for (const q of queries) {
		if (type === "movie") {
			searches.push(q);
		} else {
			searches.push(
				`${q} Season ${season}`,
				`${q} S${String(season).padStart(
					2,
					"0"
				)}`,
				`${q} S${String(season).padStart(
					2,
					"0"
				)}E${String(episode).padStart(2, "0")}`,
			);
		}
	}
	const sources = (await Promise.all(searches.map((q) => searchMagnets(q, type))))
		.flat()
		.filter(
			(source) =>
				type === "movie" || source.seasons?.includes(season!) &&
				[episode, null].includes(source.episode)
		)
		.sort((a, b) => b.score - a.score);

	console.log("Found", sources.length, "sources:");
	console.log(sources.slice(0, 5));

	if (!sources.length) {
		res.status(404).end();
		return;
	}

	const source = sources[0];
	const magnet = await source.getMagnet();
	const uuid = (await sql`
		INSERT INTO magnets (magnet, query, seasons, episode)
		VALUES (${magnet}, ${query}, ${source.seasons}, ${source.episode})
		ON CONFLICT (magnet) DO UPDATE
		SET ts = now()
		RETURNING uuid
	`)[0].uuid;

	res.json({
		uuid,
		seasons: source.seasons,
		episode: source.episode,
	});
}
