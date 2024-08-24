import { program } from "commander";
import express, { Request, Response } from "express";
import morgan from "morgan";
import handleAvailable from "./is_available";
import getRows from "./rows";
import searchTitles from "./search_titles";
import { dneError, getSeasons } from "./seasons";
import StreamManager from "./StreamManager";

program
	.option("-p, --port <port>", "listen to <port>", "1400")
	.option("-m, --mode <all|backend|stream>", "set mode", "all")
	.parse();
const opts = program.opts();

if (!process.env.DATABASE_URL || !process.env.TMDB_KEY) {
	throw "Error: both $DATABASE_URL and $TMDB_KEY must be set.";
} else if (Number.isNaN(Number(opts.port))) {
	throw `Invalid port: ${opts.port}`;
} else if (!["all", "backend", "stream"].includes(opts.mode)) {
	throw `Invalid mode: ${opts.mode}`;
}

export const port = Number(opts.port);

const app = express();

app.disable("x-powered-by");

app.use(morgan("dev"));

if (["all", "backend"].includes(opts.mode)) {
	app.get("/version", (req: Request, res: Response) => {
		res.end("0.0.0");
	});

	app.get("/:type(movie|tv)/rows.json", async (req: Request, res: Response) => {
		try {
			const rows = await getRows(req.params.type as "movie" | "tv");
			res.header("Cache-Control", "public, max-age=86400");
			res.json(rows);
		} catch (err) {
			console.error("Error getting rows:", err);
			res.status(500).end();
		}
	});

	app.get("/tv/:id(\\d{1,8})/seasons.json", async (req: Request, res: Response) => {
		try {
			const seasons = await getSeasons(req.params.id);
			res.header("Cache-Control", "public, max-age=86400");
			res.json(seasons);
		} catch (err) {
			if (err == dneError) {
				res.status(404).end();
			} else {
				console.error("Error getting seasons:", err);
				res.status(500).end();
			}
		}
	});

	app.get("/search.json", validateQuery, async (req: Request, res: Response) => {
		try {
			const blacklist = req.query.blacklist ? String(req.query.blacklist).split(",") : [];

			const isInvalidBlacklist = blacklist.find((id: string) => Number.isNaN(Number(id)));
			if (isInvalidBlacklist) {
				res.status(400).end();
				return;
			}

			const titles = await searchTitles(req.query.q as string, blacklist);
			res.header("Cache-Control", "public, max-age=86400");
			res.json(titles);
		} catch (err) {
			console.error("Error searching titles:", err);
			res.status(500).end();
		}
	});

	app.get("/movie/:id(\\d{1,8})/available.json", handleAvailable.bind(this, "movie"));
	app.get(
		"/tv/:id(\\d{1,8})/:s(\\d{1,2})/:e(\\d{1,2})/available.json",
		handleAvailable.bind(this, "tv"),
	);
}

if (["all", "stream"].includes(opts.mode)) {
	app.use("/movie/:id(\\d{1,8})/stream", StreamManager.handleConnection.bind(this, "movie"));
	app.use(
		"/tv/:id(\\d{1,8})/:s(\\d{1,2})/:e(\\d{1,2})/stream",
		StreamManager.handleConnection.bind(this, "tv"),
	);

	// DEBUG
	app.get("/stream/ip", async (req, res) => {
		res.end(await (await fetch("https://icanhazip.com")).text());
	});
}

app.listen(port, () => {
	console.log("Listening to port", port);
});

// Use middleware to validate query rather than route parameter regex because the parameter regex
// does not decode the URI and is very buggy with capture groups.
// The route would match but `req.params.query` would only contain the last character of the match.
function validateQuery(req: Request, res: Response, next: Function): void {
	if (typeof req.query.q == "string" && /^[a-z0-9 ]{1,128}$/i.test(req.query.q)) {
		next();
	} else {
		res.status(400).end();
	}
}
