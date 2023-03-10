<script lang="ts">
	import fs from "fs";
	import state from "./State";
	import { get } from "..";
	import { log, error } from "../log";

	async function getCoords(): Promise<number[]> {
		if (state.coords) {
			return state.coords;
		}

		const res = await get(
			"https://location.services.mozilla.com/v1/geolocate?key=geoclue"
		);
		const json = JSON.parse(await res.text()).location;
		return [json.lat, json.lng];
	}

	getCoords().then((coords) => {
		updateWeather();
		async function updateWeather(): Promise<void> {
			try {
				const meta = await (
					await get(
						`https://api.weather.gov/points/${coords.join(",")}`
					)
				).json();

				const forecast = (
					await (await get(meta.properties.forecast)).json()
				).properties.periods[0];

				state.weather = {
					city: meta.properties.relativeLocation.properties.city,
					temp: `${forecast.temperature} °${forecast.temperatureUnit}`,
					icon: forecast.icon.replace(/,\d+/g, ""),
					forecast: forecast.shortForecast.replace(/and/gi, "&"),
				};
				log("weather: %O", state.weather);
			} catch (err) {
				error("Weather error", err);
				setTimeout(updateWeather, 1000);
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
