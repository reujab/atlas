import express from "express";
import search from "./search";
import stream from "./stream";

const app = express();

app.get("/search/:type", async (req, res) => {
	const type = req.params.type;
	const query = String(req.query.q);
	const season = Number(req.query.s);
	const episode = Number(req.query.e);

	if (!query || (type !== "movie" && type !== "tv") || (type === "tv" && (!season || !episode))) {
		res.status(400).end();
		return;
	}

	let sources;
	if (type === "movie") {
		sources = await search(query, type);
	} else {
		sources = (
			await Promise.all([
				search(`${query} Season ${season}`, type),
				search(
					`${query} S${String(season).padStart(
						2,
						"0"
					)}`,
					type,
				),
				search(
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

	const magnet = await sources[0].getMagnet();

	console.log(magnet);
	res.end(magnet);
});

app.get("/stream", stream);

app.listen(8000, () => {
	console.log("Listening to :8000");
});
