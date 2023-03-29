import express from "express";
import fs from "fs";
import getRows from "./rows";
import getSeasons from "./seasons";
import https from "https";
import http from "http";
import morgan from "morgan";
import search from "./search";
import searchMagnets from "./magnet";
import stream from "./stream";

const app = express();

app.use(morgan("dev"));

app.use((req, res, next) => {
	if (req.query.key === process.env.KEY) {
		next();
	} else {
		res.status(403).end();
	}
});

app.get("/:type(movie|tv)/rows", async (req, res) => {
	res.json(await getRows(req.params.type as "movie" | "tv"));
});

app.get("/seasons/:id(\\d+)", async (req, res) => {
	res.json(await getSeasons(req.params.id));
});

app.get("/search", search);

app.get("/:type(movie|tv)/magnet", async (req, res) => {
	const type = req.params.type;
	const query = String(req.query.q);
	const season = Number(req.query.s);
	const episode = Number(req.query.e);

	if (!query || (type === "tv" && (!season || !episode))) {
		res.status(400).end();
		return;
	}

	let sources;
	if (type === "movie") {
		sources = await searchMagnets(query, type);
	} else {
		sources = (
			await Promise.all([
				searchMagnets(`${query} Season ${season}`, type),
				searchMagnets(
					`${query} S${String(season).padStart(
						2,
						"0"
					)}`,
					type,
				),
				searchMagnets(
					`${query} S${String(season).padStart(
						2,
						"0"
					)}E${String(episode).padStart(2, "0")}`,
					type,
				),
			])
		)
			.flat()
			.filter(
				(source) =>
					source.seasons?.includes(season) &&
					[episode, null].includes(source.episode)
			)
			.sort((a, b) => b.score - a.score);
	}

	if (!sources.length) {
		res.status(404).end();
		return;
	}

	const source = sources[0];
	const magnet = await source.getMagnet();
	const seasons = source.episode === null ? source.seasons : null;

	// cache for a week
	res.set("Cache-Control", "public, max-age=604800");
	res.json({
		magnet,
		seasons,
	});
});

app.get("/stream", stream);

app.use("/update", express.static("/usr/share/atlas-updater"));

app.listen(Number(process.env.PORT), () => {
	console.log("Listening to port", process.env.PORT);
});

export async function get(...args: Parameters<typeof fetch>): Promise<Response> {
	const start = Date.now();
	let lastErr;

	for (let i = 0; i < 4; i++) {
		if (Date.now() - start > 5000) break;

		console.log(`Getting ${args[0]}`);
		try {
			// eslint-disable-next-line no-await-in-loop
			const res = await fetch(...args);
			console.log(`Reply at ${(Date.now() - start) / 1000}s`);

			lastErr = new Error(`Status: ${res.status}`);

			if (res.status >= 500) continue;
			if (res.status !== 200) break;

			return res;
		} catch (err) {
			lastErr = err;

			console.error("Fetch error", err);

			if ((err as Error).message?.startsWith("status:")) break;
		}
	}

	throw lastErr;
}
