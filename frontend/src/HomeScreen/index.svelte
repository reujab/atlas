<script lang="ts" context="module">
	export interface Tile {
		title: string
		onClick?: () => void
		path?: string
		icon: any
	}
</script>

<script lang="ts">
	import Clock from "./Clock.svelte";
	import HomeTile from "./HomeTile.svelte";
	import VPNStatus from "./VPNStatus.svelte";
	import Weather from "./Weather.svelte";
	import childProcess from "child_process";
	import seedrandom from "seedrandom";
	import state from "./State";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	// set background based on time of day
	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const max = timeOfDay === "day" ? 4 : 23;
	const rng = seedrandom(new Date().getDay().toString());
	const index = Math.floor(rng() * max);
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
		{
			title: "Reboot",
			onClick() {
				childProcess.execSync("/sbin/reboot");
			},
			icon: require("../img/shutdown.png"),
		},
	];

	function gamepadHandler(button: string): void {
		switch (button) {
			case "A":
				const tile = tiles[state.activeTile];
				tile.onClick?.();
				if (tile.path) location.hash = `#${tile.path}`;
				break;
			case "up":
				if (state.activeTile % 2 === 1) state.activeTile -= 1;
				break;
			case "down":
				if (state.activeTile % 2 === 0) state.activeTile += 1;
				break;
			case "left":
				if (state.activeTile >= 2) state.activeTile -= 2;
				break;
			case "right":
				if (state.activeTile + 2 < tiles.length) state.activeTile += 2;
				break;
		}
		state.activeTile = Math.max(
			0,
			Math.min(tiles.length - 1, state.activeTile)
		);
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
		<div
			class="flex flex-col gap-48 flex-wrap text-black grow content-start"
		>
			{#each tiles as tile, i}
				<HomeTile {tile} active={state.activeTile === i} />
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
