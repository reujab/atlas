import express, { Request, Response } from "express";
import morgan from "morgan";
import getUUID from "./magnet/get_uuid";
import getRows from "./rows";
import searchTitles from "./search_titles";
import { dneError, getSeasons } from "./seasons";
import initStream from "./stream/init";
import { keepalive } from "./stream/keepalive";
import { proxy } from "./stream/proxy";

if (!process.env.DATABASE_URL || !process.env.TMDB_KEY) {
	console.error("Error: both $DATABASE_URL and $TMDB_KEY must be set.");
	process.exit(1);
}

export const port = Number(process.env.PORT || 8000);

const app = express();

const uuidParam = ":uuid([a-z0-9-]{36})";

app.disable("x-powered-by");

app.use(morgan("dev"));

app.get("/rows/:type(movie|tv)", async (req, res) => {
	try {
		res.json(await getRows(req.params.type as "movie" | "tv"));
	} catch (err) {
		console.error("Error getting rows:", err);
		res.status(500).end();
	}
});

app.get("/seasons/:id(\\d{1,8})", async (req, res) => {
	try {
		res.json(await getSeasons(req.params.id));
	} catch (err) {
		if (err == dneError) {
			res.status(404).end();
		} else {
			console.error("Error getting seasons:", err);
			res.status(500).end();
		}
	}
});

app.get("/search/:query", validateQuery, async (req, res) => {
	try {
		const blacklist = req.query.blacklist ? String(req.query.blacklist).split(",") : [];

		const is_invalid_blacklist = blacklist.find((id: string) => Number.isNaN(Number(id)));
		if (is_invalid_blacklist) {
			res.status(400).end();
			return;
		}

		res.json(await searchTitles(req.params.query, blacklist));
	} catch (err) {
		console.error("Error searching titles:", err);
		res.status(500).end();
	}
});

app.get("/get-uuid/:type(movie|tv)/:query", validateQuery, (req, res) => {
	getUUID(req, res).catch((err) => {
		console.error("Error getting UUID:", err);
		res.status(500).end();
	});
});

app.get(`/init/${uuidParam}`, (req, res) => {
	initStream(req, res).catch((err) => {
		console.error("Error initializing stream:", err);
		res.status(500).end();
	});
})

app.head(`/keepalive/${uuidParam}`, keepalive);

app.use(`/stream/${uuidParam}/`, proxy);

app.use("/update", express.static("/usr/share/atlas-updater"));

app.listen(port, () => {
	console.log("Listening to port", port);
});

// Use middleware to validate query rather than route parameter regex because the parameter regex
// does not decode the URI and is very buggy with capture groups.
// The route would match but `req.params.query` would only contain the last character of the match.
// Upgrading to Express v5 did not fix the issue.
//
// Considering the issues I've had with Express's routing, I will consider switching to another
// framework, or better yet, rewriting in Go using anacrolix/torrent.
// Unfortunately when I benchmarked the two libraries in early 2023, WebTorrent performed much,
// much better than anacrolix/torrent, so that rewrite may have to wait. This workaround will do
// for now.
function validateQuery(req: Request, res: Response, next: Function): void {
	if (/^[a-z0-9 ]{1,128}$/i.test(req.params.query)) {
		next();
	} else {
		res.status(400).end();
	}
}
