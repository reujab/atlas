<script>
	import HomeTile from "./HomeTile";
	import FaFilm from "svelte-icons/fa/FaFilm.svelte";
	import FaTv from "svelte-icons/fa/FaTv.svelte";

	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const index = Math.floor(Math.random() * (timeOfDay === "day" ? 4 : 23));
	console.log("random number =", index);
	const img = `url(./backgrounds/${timeOfDay}/${index}.webp)`;
</script>

<div id="main" class="h-screen px-48" style="background-image: {img}">
	<div
		class="overflow-x-scroll flex flex-col gap-48 justify-center content-start flex-wrap h-full"
	>
		<HomeTile title="Movies" icon={FaFilm} iconClass="text-indigo-700" />
		<HomeTile title="TV Shows" icon={FaTv} iconClass="text-lime-700" />
		<HomeTile title="App #1" icon={FaFilm} iconClass="text-indigo-700" />
		<HomeTile title="App #2" icon={FaTv} iconClass="text-lime-700" />
	</div>
</div>

<style>
	:global(body) {
		background: black;
	}

	#main {
		background-size: cover;
		font-family: Cantarell;
		border-radius: 25px;
	}
</style>
