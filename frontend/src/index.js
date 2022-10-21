import HomeScreen from "./HomeScreen/index.svelte";
import Play from "./Play/index.svelte";
import Router, { routes } from "svelte-hash-router";
import Search from "./Search/index.svelte";
import SearchResults from "./SearchResults/index.svelte";
import Seasons from "./Seasons/index.svelte";
import TitleDetails from "./TitleDetails/index.svelte";
import Titles from "./Titles/index.svelte";
import Trailer from "./Trailer/index.svelte";
import child_process from "child_process";
import { cacheGenres } from "./db";
import { error, log } from "./log";
import { subscribe } from "./gamepad";

let lastKill = 0;
let killTimeout;

addEventListener("error", (err) => {
	if (err.message === "Uncaught EvalError: Possible side-effect in debug-evaluate" || err.message.startsWith("Uncaught SyntaxError")) {
		return;
	}

	error("Uncaught error: %O", err);
});

cacheGenres();

routes.set({
	"/": HomeScreen,
	"/search": Search,
	"/results/:query": SearchResults,
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
		child_process.exec("killall -STOP tmdbd");
		lastKill = Date.now();
	}

	clearTimeout(killTimeout);
	killTimeout = setTimeout(() => {
		child_process.exec("killall -CONT tmdbd");
	}, 1000 * 60 * 10);
});

export default new Router({
	target: document.body,
});

export async function get(...args) {
	const start = Date.now();
	let lastErr;

	for (let i = 0; i < 4; i++) {
		if (Date.now() - start > 5000) {
			break;
		}

		try {
			log(`Getting ${args[0]}`);
			const res = await fetch(...args);
			if (res.status >= 400 && res.status < 500) {
				return Promise.reject(`4xx status: ${res.status}`);
			}
			if (res.status >= 500) {
				lastErr = new Error(`status: ${res.status}`);
				continue;
			}
			if (res.status !== 200) {
				throw new Error(`status: ${res.status}`);
			}

			return res;
		} catch (err) {
			lastErr = err;
			if (err instanceof DOMException) {
				break;
			}
			error("%O", err);
		}
	}

	return Promise.reject(lastErr);
}
