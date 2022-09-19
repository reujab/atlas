import "./db";
import HomeScreen from "./HomeScreen";
import MovieDetails from "./MovieDetails";
import Movies from "./Movies";
import Router, { routes } from "svelte-hash-router";
import Search from "./Search";
import SearchResults from "./SearchResults";
import Trailer from "./Trailer";
import { error } from "./log";

addEventListener("error", (err) => {
	error("Uncaught error: %O", err);
})

routes.set({
	"/": HomeScreen,
	"/movies": Movies,
	"/movies/:id": MovieDetails,
	"/results/:query": SearchResults,
	"/trailer/:id": Trailer,
	"/search": Search,
});

export default new Router({
	target: document.body,
});
