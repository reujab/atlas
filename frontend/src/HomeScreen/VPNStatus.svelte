<script lang="ts">
	import child_process from "child_process";
	import { error } from "../log";
	import { fetchJSON } from "..";
	import { onDestroy } from "svelte";

	let connected: null | boolean = null;
	let location: null | string = null;
	function getStatus() {
		child_process.exec("windscribe status", (err, stdout, stderr) => {
			if (err) {
				error("error running 'windscribe status': %O", err);
				connected = false;
				return;
			}

			const lines = stdout.trim().split("\n");
			const lastLine = lines[lines.length - 1];
			const lastStatus = connected;
			connected = lastLine.slice(0, 9) === "CONNECTED";

			if (
				(connected !== lastStatus && lastStatus !== null) ||
				!location
			) {
				getLocation();
			}

			if (!connected) {
				error(`disconnected from vpn: ${stdout}${stderr}`);
			}
		});
	}

	async function getLocation() {
		let json;
		try {
			json = await fetchJSON("https://ipapi.co/json/");
		} catch (err) {
			error("error fetching from ipapi.co: %O", err);
			return;
		}

		if (json.city) {
			const state =
				json.region.length > 12 ? json.region_code : json.region;
			location = `${json.city}, ${state}`;
		}
	}

	getStatus();
	getLocation();

	const interval = setInterval(getStatus, 5000);
	onDestroy(() => {
		clearInterval(interval);
	});
</script>

{#if connected !== null}
	<hr class="m-8" />

	<div class="flex flex-col gap-2">
		<div class="text-3xl">VPN Status</div>

		<div class="text-6xl">
			{#if connected}
				<span class="text-green-400">CONNECTED</span>
			{:else}
				<span class="text-red-400">DISCONNECTED</span>
			{/if}
		</div>

		{#if location}
			<div class="text-4xl">{location}</div>
		{/if}
	</div>
{/if}
