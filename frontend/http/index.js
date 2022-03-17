import HomeScreen from "./HomeScreen"
import Movies from "./Movies"
import Pictures from "./Pictures"
import Router, { routes } from "svelte-hash-router"

routes.set({
	"/": HomeScreen,
	"/movies": Movies,
	"/pictures": Pictures,
})

export default new Router({
	target: document.body,
})
