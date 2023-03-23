// must be imported first
import { error, log } from "./log";

import HomeScreen from "./HomeScreen/index.svelte";
import Init from "./Init/index.svelte";
import Play from "./Play/index.svelte";
import Router, { routes } from "svelte-hash-router";
import Search from "./Search/index.svelte";
import Seasons from "./Seasons/index.svelte";
import TitleDetails from "./TitleDetails/index.svelte";
import Titles from "./Titles/index.svelte";
import Trailer from "./Trailer/index.svelte";
import Wifi from "./Wifi/index.svelte";

addEventListener("error", (err) => {
	if (
		err.message === "Uncaught EvalError: Possible side-effect in debug-evaluate" ||
		err.message.startsWith("Uncaught SyntaxError")
	) return;

	error("Uncaught error", err);
});

routes.set({
	"/": Init,
	"/wifi": Wifi,
	"/home": HomeScreen,
	"/search": Search,
	"/results/:query/play": Play,
	"/tv/:id/view": Seasons,

	"/:type": Titles,
	"/:type/:id": TitleDetails,
	"/:type/:id/play": Play,
	"/:type/:id/trailer": Trailer,

	"*": HomeScreen,
});

export default new Router({
	target: document.body,
});

export async function get(...args: Parameters<typeof fetch>): Promise<Response> {
	const start = Date.now();
	let lastErr;

	for (let i = 0; i < 4; i++) {
		if (Date.now() - start > 5000) break;

		log(`Getting ${args[0]}`);
		try {
			// eslint-disable-next-line no-await-in-loop
			const res = await fetch(...args);
			log(`Reply at ${(Date.now() - start) / 1000}s`);

			lastErr = new Error(`Status: ${res.status}`);

			if (res.status >= 500) continue;
			if (res.status !== 200) break;

			return res;
		} catch (err) {
			lastErr = err;

			error("Fetch error", err);

			if ((err as Error).message?.startsWith("status:")) break;
		}
	}

	throw lastErr;
}
