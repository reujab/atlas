import "./db";
import HomeScreen from "./HomeScreen";
import Router, { routes } from "svelte-hash-router";
import Search from "./Search/index.svelte";
import SearchResults from "./SearchResults/index.svelte";
import Seasons from "./Seasons/index.svelte";
import TitleDetails from "./TitleDetails/index.svelte";
import Titles from "./Titles/index.svelte";
import Trailer from "./Trailer/index.svelte";
import { error } from "./log";

addEventListener("error", (err) => {
	error("Uncaught error: %O", err);
})

routes.set({
	"/": HomeScreen,
	"/search": Search,
	"/results/:query": SearchResults,
	"/:type": Titles,
	"/:type/:id": TitleDetails,
	"/:type/:id/trailer": Trailer,
	"/tv/:id/view": Seasons,

	"*": HomeScreen,
});

export default new Router({
	target: document.body,
});
