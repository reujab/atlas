<script>
	import HomeTile from "./HomeTile";
	import FaFilm from "svelte-icons/fa/FaFilm.svelte";
	import FaTv from "svelte-icons/fa/FaTv.svelte";

	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const index = Math.floor(Math.random() * (timeOfDay === "day" ? 4 : 23));
	console.log("random number =", index);
	const img = `url(./backgrounds/${timeOfDay}/${index}.webp)`;

	const tiles = [
		{ title: "Movies", icon: FaFilm, iconClass: "text-indigo-700" },
		{ title: "TV Shows", icon: FaTv, iconClass: "text-lime-700" },
	];

	let activeTile = 0

	function onGamepadConnect() {
		activeTile = 1
	}
</script>

<svelte:window on:gamepadconnected={onGamepadConnect} />
<div id="main" class="h-screen px-48" style="background-image: {img}">
	<div
		class="flex flex-col gap-48 justify-center content-start flex-wrap h-full"
	>
		{#each tiles as tile, i}
			<HomeTile
				title={tile.title}
				icon={tile.icon}
				iconClass={tile.iconClass}
				active={activeTile === i}
			/>
		{/each}
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
