<script lang="ts" context="module">
	export interface Tile {
		title: string;
		path: string;
		icon: any;
	}
</script>

<script lang="ts">
	import Clock from "./Clock.svelte";
	import HomeTile from "./HomeTile.svelte";
	import Weather from "./Weather.svelte";
	import VPNStatus from "./VPNStatus.svelte";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	// set background based on time of day
	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const index = Math.floor(Math.random() * (timeOfDay === "day" ? 4 : 23));
	const img = `url(./backgrounds/${timeOfDay}/${index}.webp)`;

	// home tiles
	const tiles: Tile[] = [
		{
			title: "Movies",
			path: "/movie",
			icon: require("../img/popcorn.png"),
		},
		{
			title: "TV Shows",
			path: "/tv",
			icon: require("../img/tv.png"),
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
	<div class="flex grow h-[44rem]">
		<div class="flex flex-col gap-48 flex-wrap text-black grow">
			{#each tiles as tile, i}
				<HomeTile {tile} active={activeTile === i} />
			{/each}
		</div>
		<div class="self-center">
			<div class="bg-gray-600/70 rounded-lg p-6 text-right">
				<Clock />

				<Weather />

				<VPNStatus />
			</div>
		</div>
	</div>
</div>
