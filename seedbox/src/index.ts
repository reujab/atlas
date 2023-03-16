import express from "express";
import genres, { expandGenres } from "./genres";
import morgan from "morgan";
import search from "./search";
import searchMagnets from "./magnet";
import sql from "./sql";
import stream from "./stream";

const app = express();

app.use(morgan("dev"));

app.get("/:type(movie|tv)/trending", async (req, res) => {
	const trending = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating, poster
		FROM titles
		WHERE type = ${req.params.type}
		AND language = 'en'
		AND rating >= 'PG-13'
		ORDER BY popularity DESC NULLS LAST
		LIMIT 100
	`;
	expandGenres(trending);
	res.json(trending);
});

app.get("/:type(movie|tv)/top", async (req, res) => {
	const topRated = await sql`
		SELECT id, type, title, genres, overview, released, trailer, rating, poster
		FROM titles
		WHERE type = ${req.params.type}
		AND votes >= 1000
		AND language = 'en'
		ORDER BY score DESC NULLS LAST, popularity DESC NULLS LAST
		LIMIT 100
	`;
	expandGenres(topRated);
	res.json(topRated);
});

app.get("/:type(movie|tv)/genres", genres);

app.get("/seasons/:id(\\d+)", async (req, res) => {
	const seasons = [];

	for (let i = 0, keys = 20; keys === 20; i++) {
		const append = Array(20)
			.fill(null)
			.map((_, j) => `season/${i * 20 + j + 1}`)
			.join(",");
		// eslint-disable-next-line no-await-in-loop
		const json = await (await fetch(
			`https://api.themoviedb.org/3/tv/${req.params.id}?api_key=${process.env.TMDB_KEY}&append_to_response=${append}`
		)).json();
		keys = Object.keys(json).filter((key) => key.startsWith("season/"))
			.length;

		for (let j = 0; j < 20; j++) {
			const season = json[`season/${i * 20 + j + 1}`];
			if (season?.episodes.length) {
				seasons.push({
					number: season.season_number,
					episodes: season.episodes.map((episode: any) => ({
						number: episode.episode_number,
						date: episode.air_date,
						name: episode.name,
						overview: episode.overview,
						runtime: episode.runtime,
						still: episode.still_path,
					})),
					activeEpisode: 0,
					ele: null,
					episodesEle: null,
				});
			}
		}
	}

	res.json(seasons);
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

	const magnet = await sources[0].getMagnet();

	console.log(magnet);
	res.end(magnet);
});

app.get("/stream", stream);

app.listen(8000, () => {
	console.log("Listening to :8000");
});
