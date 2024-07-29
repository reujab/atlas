import express, { Request, Response } from "express";
import morgan from "morgan";
import StreamManager from "./StreamManager";
import handleAvailable from "./is_available";
import getRows from "./rows";
import searchTitles from "./search_titles";
import { dneError, getSeasons } from "./seasons";

if (!process.env.DATABASE_URL || !process.env.TMDB_KEY) {
	console.error("Error: both $DATABASE_URL and $TMDB_KEY must be set.");
	process.exit(1);
}

export const port = Number(process.env.PORT || 8000);

const app = express();

app.disable("x-powered-by");

app.use(morgan("dev"));

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

app.use("/movie/:id(\\d{1,8})/stream", StreamManager.handleConnection.bind(this, "movie"));
app.use(
	"/tv/:id(\\d{1,8})/:s(\\d{1,2})/:e(\\d{1,2})/stream",
	StreamManager.handleConnection.bind(this, "tv"),
);

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
