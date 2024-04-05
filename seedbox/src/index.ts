import express from "express";
import morgan from "morgan";
import getUUID from "./magnet";
import getRows from "./rows";
import searchTitles from "./search";
import getSeasons from "./seasons";
import * as stream from "./stream";

if (!process.env.DATABASE_URL || !process.env.TMDB_KEY) {
	console.error("Error: both $DATABASE_URL and $TMDB_KEY must be set.");
	process.exit(1);
}

const app = express();
const port = Number(process.env.PORT || 8000);

app.disable("x-powered-by");

app.use(morgan("dev"));

app.get("/:type(movie|tv)/rows", async (req, res) => {
	res.json(await getRows(req.params.type as "movie" | "tv"));
});

app.get("/seasons/:id(\\d+)", async (req, res) => {
	res.json(await getSeasons(req.params.id));
});

app.get("/search", searchTitles);

app.get("/:type(movie|tv)/uuid", getUUID);

app.get("/init", stream.init);

app.delete("/stream/:uuid", stream.deleteStream);

app.use("/stream/:uuid/", stream.proxy);

app.use("/update", express.static("/usr/share/atlas-updater"));

app.listen(port, () => {
	console.log("Listening to port", port);
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
