import { Request, Response } from "express";
import aliases from "./aliases";
import findSources, { Source } from "./find_sources";
import sql from "./sql";
import Title from "./Title";

export default async function handle(
	type: "movie" | "tv",
	req: Request,
	res: Response,
): Promise<void> {
	let available;
	try {
		const season = req.params.s ? Number(req.params.s) : null;
		const episode = req.params.e ? Number(req.params.e) : null;
		available = await isAvailable(type, Number(req.params.id), season, episode);
	} catch (err) {
		console.error("Error searching sources:", err);
		res.status(500).end();
		return;
	}
	res.json(available);
}

async function isAvailable(
	type: "movie" | "tv",
	id: number,
	season: null | number,
	episode: null | number,
): Promise<boolean> {
	await sql`
		DELETE FROM sources
		WHERE ts < NOW() - INTERVAL '1 day'
	`;
	const exists = await sql`
		SELECT EXISTS (
			SELECT 1 FROM sources
			WHERE type = ${type}
			AND id = ${id}
			AND (seasons IS NULL OR ${season} = ANY(seasons))
			AND (episode IS NULL OR episode = ${episode})
			AND NOT defunct
		)
	`;
	if (exists[0].exists) return true;

	const rows = await sql`
		SELECT * FROM titles
		WHERE type = ${type}
		AND id = ${id}
	`;
	if (!rows.length) return false;
	const title = rows[0] as Title;

	let searches = [title.title];
	for (const alias of aliases) {
		if (alias.regex.test(title.title)) {
			if (!alias.add) searches = [];
			searches.push(title.title.replace(alias.regex, alias.replace));
		}
	}

	searches = searches.flatMap((query) => {
		if (type === "movie") {
			return title.released ? `${query} ${title.released.getFullYear()}` : query;
		}

		const paddedSeason = String(season).padStart(2, "0");
		return [
			`${query} Season ${season}`,
			`${query} S${paddedSeason}E${String(episode).padStart(2, "0")}`,
			`${query} S${paddedSeason}`,
		];
	});

	const unfilteredSources = (
		await Promise.all(searches.map((query) => findSources(query, type)))
	).flat();
	const sources = unfilteredSources
		.filter(
			(source, i) =>
				// Filter out duplicates.
				unfilteredSources.findIndex((s) => source.score === s.score) == i &&
				// Filter out non-matching sources.
				(type === "movie" ||
					(source.seasons?.includes(season!) && [episode, null].includes(source.episode))),
		)
		.sort((a, b) => b.score - a.score);

	console.log("Found", sources.length, "sources:", sources.slice(0, 3));

	const candidates = await Promise.all(
		sources
			.filter((source) => source.seeders >= 5)
			.slice(0, 3)
			.map(async (source) => {
				const src = source as Source & { magnet: string };
				src.magnet = await src.getMagnet();
				return src;
			}),
	);
	if (!candidates.length) return false;

	await sql.begin(async (trans) => {
		await Promise.all(
			candidates.map((source, i) => {
				return trans`
					INSERT INTO sources (magnet, type, id, seasons, episode, score)
					VALUES (${source.magnet}, ${type}, ${id}, ${source.seasons}, ${source.episode}, ${source.score})
					ON CONFLICT (magnet)
					DO UPDATE
					SET ts = now()
				`;
			}),
		);
	});

	return true;
}
