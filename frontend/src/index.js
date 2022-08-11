import "./db";
import HomeScreen from "./HomeScreen";
import MovieDetails from "./MovieDetails";
import Movies from "./Movies";
import Router, { routes } from "svelte-hash-router";
import SearchResults from "./SearchResults";
import { error } from "./log";
import Trailer from "./Trailer";

routes.set({
	"/": HomeScreen,
	"/movies": Movies,
	"/movies/details/:id": MovieDetails,
	"/search/:query": SearchResults,
	"/trailer/:id": Trailer,
});

export default new Router({
	target: document.body,
});

addEventListener("error", (err) => {
	error("Uncaught error: %O", err);
})
