import "./db";
import HomeScreen from "./HomeScreen";
import Router, { routes } from "svelte-hash-router";
import Search from "./Search";
import SearchResults from "./SearchResults";
import TitleDetails from "./TitleDetails";
import Titles from "./Titles";
import Trailer from "./Trailer";
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
});

export default new Router({
	target: document.body,
});
