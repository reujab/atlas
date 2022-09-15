<script lang="ts">
	import HomeTile from "./HomeTile/index.svelte";
	import fs from "fs";
	import { log, error } from "../log";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	interface Tile {
		title: string;
		path: string;
		icon: any;
	}

	// set background based on time of day
	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const index = Math.floor(Math.random() * (timeOfDay === "day" ? 4 : 23));
	const img = `url(./backgrounds/${timeOfDay}/${index}.webp)`;

	// home tiles
	const tiles: Tile[] = [
		{
			title: "Movies",
			path: "/movies",
			icon: require("../img/popcorn.png"),
		},
		{
			title: "TV Shows",
			path: "/shows",
			icon: require("../img/tv.png"),
		},
	];
	let activeTile = 0;
	let date = new Date();

	const interval = setInterval(() => {
		date = new Date();
	}, 50);

	let weather: any;
	fs.readFile("/tmp/geo.json", async (err, geo) => {
		if (err) {
			error("error reading geo.json: %O", err);
			return;
		}

		const coords = JSON.parse(geo.toString());
		const metaRes = await fetch(
			`https://api.weather.gov/points/${coords.join(",")}`
		);
		const meta = await metaRes.json();

		const forecastRes = await fetch(meta.properties.forecast);
		const forecast = (await forecastRes.json()).properties.periods[0];

		weather = {
			city: meta.properties.relativeLocation.properties.city,
			temp: `${forecast.temperature} °${forecast.temperatureUnit}`,
			icon: forecast.icon,
			description: forecast.shortForecast,
		};
		log("%O", weather);
	});

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
		clearInterval(interval);
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
				<div class="flex flex-col gap-2">
					<div class="text-3xl">
						{date.toLocaleDateString("en-US", {
							weekday: "long",
						})}
					</div>
					<div class="text-5xl">
						{date.toLocaleDateString("en-us", {
							year: "numeric",
							month: "short",
							day: "numeric",
						})}
					</div>
					<div class="flex text-7xl justify-end">
						{#each date.toLocaleTimeString("en-US") as char}
							<span
								class="overflow-hidden"
								class:mono={!Number.isNaN(Number(char))}
							>
								{char}
							</span>
						{/each}
					</div>
				</div>

				{#if weather}
					<hr class="m-8" />

					<div class="text-3xl">{weather.city}</div>
					<div
						class="text-7xl flex justify-end gap-4 my-2 items-center"
					>
						<img
							src={weather.icon}
							alt=""
							class="rounded-full inline-block"
						/>
						<span>{weather.temp}</span>
					</div>
					<div class="text-4xl">{weather.description}</div>
				{/if}
			</div>
		</div>
	</div>
</div>

<style>
	.mono {
		min-width: 0.6em;
		max-width: 0.6em;
		text-align: center;
	}
</style>
