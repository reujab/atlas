import "./db";
import HomeScreen from "./HomeScreen";
import MovieDetails from "./MovieDetails";
import Movies from "./Movies";
import Router, { routes } from "svelte-hash-router";
import SearchResults from "./SearchResults";
import Watch from "./Watch"

requestAnimationFrame = setTimeout;

routes.set({
	"/": HomeScreen,
	"/movies": Movies,
	"/movies/details/:id": MovieDetails,
	"/search/:query": SearchResults,
	"/watch": Watch,
});

export default new Router({
	target: document.body,
});
