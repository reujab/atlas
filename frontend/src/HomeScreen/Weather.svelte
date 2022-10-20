<script lang="ts">
	import fs from "fs";
	import state from "./State";
	import { fetchJSON } from "..";
	import { log, error } from "../log";

	fs.readFile("/tmp/geo.json", async (err, geo) => {
		if (err) {
			error("error reading geo.json: %O", err);
			return;
		}

		const coords = JSON.parse(geo.toString());

		getWeather();
		async function getWeather() {
			try {
				const meta = await fetchJSON(
					`https://api.weather.gov/points/${coords.join(",")}`
				);

				const forecast = (await fetchJSON(meta.properties.forecast))
					.properties.periods[0];

				state.weather = {
					city: meta.properties.relativeLocation.properties.city,
					temp: `${forecast.temperature} °${forecast.temperatureUnit}`,
					icon: forecast.icon.replace(/,\d+/g, ""),
					forecast: forecast.shortForecast.replace(/and/gi, "&"),
				};
				log("%O", state.weather);
			} catch (err) {
				error("error getting weather: %O", err);
				setTimeout(getWeather, 1000);
			}
		}
	});
</script>

{#if state.weather}
	<hr class="m-8" />

	<div class="text-3xl">{state.weather.city}</div>
	<div class="text-7xl flex justify-end gap-4 my-2 items-center">
		<img
			src={state.weather.icon}
			alt=""
			class="rounded-full inline-block"
		/>
		<span>{state.weather.temp}</span>
	</div>
	<div class="text-4xl">{state.weather.forecast}</div>
{/if}
