<script lang="ts">
	import fs from "fs";
	import { log, error } from "../log";

	interface Weather {
		city: string;
		temp: string;
		icon: string;
		forecast: string;
	}

	let weather: null | Weather = null;

	fs.readFile("/tmp/geo.json", async (err, geo) => {
		if (err) {
			error("error reading geo.json: %O", err);
			return;
		}

		const coords = JSON.parse(geo.toString());

		getWeather();
		async function getWeather() {
			try {
				const metaRes = await fetch(
					`https://api.weather.gov/points/${coords.join(",")}`
				);
				const meta = await metaRes.json();

				const forecastRes = await fetch(meta.properties.forecast);
				const forecast = (await forecastRes.json()).properties
					.periods[0];

				weather = {
					city: meta.properties.relativeLocation.properties.city,
					temp: `${forecast.temperature} °${forecast.temperatureUnit}`,
					icon: forecast.icon.replace(/,\d+/g, ""),
					forecast: forecast.shortForecast.replace(/and/gi, "&"),
				};
				log("%O", weather);
			} catch (err) {
				error("error getting weather: %O", err);
				setTimeout(getWeather, 1000);
			}
		}
	});
</script>

{#if weather}
	<hr class="m-8" />

	<div class="text-3xl">{weather.city}</div>
	<div class="text-7xl flex justify-end gap-4 my-2 items-center">
		<img src={weather.icon} alt="" class="rounded-full inline-block" />
		<span>{weather.temp}</span>
	</div>
	<div class="text-4xl">{weather.forecast}</div>
{/if}
