import HomeScreen from "./HomeScreen"
import Movies from "./Movies"
import Router, { routes } from "svelte-hash-router"

routes.set({
	"/": HomeScreen,
	"/movies": Movies,
})

export default new Router({
	target: document.body,
})
