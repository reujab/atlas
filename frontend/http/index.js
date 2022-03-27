import "./db"
import HomeScreen from "./HomeScreen"
import MovieDetails from "./MovieDetails"
import Movies from "./Movies"
import Router, { routes } from "svelte-hash-router"
import WatchMovie from "./WatchMovie"

routes.set({
	"/": HomeScreen,
	"/movies": Movies,
	"/movies/details/:id": MovieDetails,
	"/movies/watch/:id": WatchMovie,
})

export default new Router({
	target: document.body,
})
