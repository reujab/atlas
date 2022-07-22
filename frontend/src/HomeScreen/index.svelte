<script lang="ts">
	import HomeTile from "./HomeTile";
	import FaFilm from "svelte-icons/fa/FaFilm.svelte";
	import FaTv from "svelte-icons/fa/FaTv.svelte";
	import { subscribe, unsubscribe } from "../gamepad";
	import { onDestroy } from "svelte";

	interface Tile {
		title: string;
		path: string;
		icon: any;
		iconClass: string;
	}

	// set background based on time of day
	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const index = Math.floor(Math.random() * (timeOfDay === "day" ? 4 : 23));
	const img = `url(./backgrounds/${timeOfDay}/${index}.webp)`;

	// home tiles
	const tiles = [
		{
			title: "Movies",
			path: "/movies",
			icon: FaFilm,
			iconClass: "text-indigo-700",
		},
		{
			title: "TV Shows",
			path: "/shows",
			icon: FaTv,
			iconClass: "text-lime-700",
		},
	];
	let activeTile = 0;

	function gamepadHandler(button: string) {
		switch (button) {
			case "A":
				location.hash = `#${tiles[activeTile].path}`;
				break;
			case "up":
				if (activeTile % 2 == 1) {
					activeTile -= 1;
				}
				break;
			case "down":
				if (activeTile % 2 == 0) {
					activeTile += 1;
				}
				break;
			case "left":
				if (activeTile >= 2) {
					activeTile -= 2;
				}
				break;
			case "right":
				if (activeTile + 2 < tiles.length) {
					activeTile += 2;
				}
				break;
		}
		activeTile = Math.max(0, Math.min(tiles.length - 1, activeTile));
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div
	class="h-screen px-48 rounded-[25px] bg-cover flex items-center"
	style="background-image: {img}"
>
	<div class="flex flex-col gap-48 flex-wrap h-[44rem]">
		{#each tiles as tile, i}
			<HomeTile {tile} active={activeTile === i} />
		{/each}
	</div>
</div>
