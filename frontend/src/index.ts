import HomeScreen from "./HomeScreen/index.svelte";
import Play from "./Play/index.svelte";
import Router, { routes } from "svelte-hash-router";
import Search from "./Search/index.svelte";
import Seasons from "./Seasons/index.svelte";
import TitleDetails from "./TitleDetails/index.svelte";
import Titles from "./Titles/index.svelte";
import Trailer from "./Trailer/index.svelte";
import childProcess from "child_process";
import { cacheGenres } from "./db";
import { error, log } from "./log";
import { subscribe } from "./gamepad";

let lastKill = 0;
let killTimeout: NodeJS.Timer;

addEventListener("error", (err) => {
	if (
		err.message === "Uncaught EvalError: Possible side-effect in debug-evaluate" ||
		err.message.startsWith("Uncaught SyntaxError")
	) return;

	error("Uncaught error", err);
});

cacheGenres();

routes.set({
	"/": HomeScreen,
	"/search": Search,
	"/results/:query/play": Play,
	"/tv/:id/view": Seasons,

	"/:type": Titles,
	"/:type/:id": TitleDetails,
	"/:type/:id/play": Play,
	"/:type/:id/trailer": Trailer,

	"*": HomeScreen,
});

subscribe(() => {
	if (Date.now() - lastKill > 10000) {
		childProcess.exec("killall -STOP tmdbd");
		lastKill = Date.now();
	}

	clearTimeout(killTimeout);
	killTimeout = setTimeout(() => {
		childProcess.exec("killall -CONT tmdbd");
	}, 1000 * 60 * 10);
});

export default new Router({
	target: document.body,
});

export async function get(...args: Parameters<typeof fetch>): Promise<Response> {
	const start = Date.now();
	let lastErr;

	for (let i = 0; i < 4; i++) {
		if (Date.now() - start > 5000) break;

		try {
			log(`Getting ${args[0]}`);
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
