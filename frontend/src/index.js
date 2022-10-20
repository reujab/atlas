import HomeScreen from "./HomeScreen/index.svelte";
import Play from "./Play/index.svelte";
import Router, { routes } from "svelte-hash-router";
import Search from "./Search/index.svelte";
import SearchResults from "./SearchResults/index.svelte";
import Seasons from "./Seasons/index.svelte";
import TitleDetails from "./TitleDetails/index.svelte";
import Titles from "./Titles/index.svelte";
import Trailer from "./Trailer/index.svelte";
import { cacheGenres } from "./db";
import { error } from "./log";

addEventListener("error", (err) => {
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

export default new Router({
	target: document.body,
});

export async function fetchJSON(url, signal) {
	let lastErr;

	for (let i = 0; i < 3; i++) {
		try {
			const res = await fetch(url, { signal });
			if (res.status >= 400 && res.status < 500) {
				return Promise.reject(`4xx status: ${res.status}`);
			}
			if (res.status !== 200) {
				throw new Error(`status: ${res.status}`);
			}

			return await res.json();
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
