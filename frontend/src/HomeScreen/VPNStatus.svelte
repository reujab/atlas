<script lang="ts">
	import child_process from "child_process";
	import state from "./State";
	import { error } from "../log";
	import { get } from "..";
	import { onDestroy } from "svelte";

	const { vpn } = state;

	function getStatus() {
		child_process.exec("windscribe status", (err, stdout, stderr) => {
			if (err) {
				error("error running 'windscribe status': %O", err);
				vpn.connected = false;
				return;
			}

			const lines = stdout.trim().split("\n");
			const lastLine = lines[lines.length - 1];
			const lastStatus = vpn.connected;
			vpn.connected = lastLine.slice(0, 9) === "CONNECTED";

			if (
				(vpn.connected !== lastStatus && lastStatus !== null) ||
				!vpn.location
			) {
				getLocation();
			}

			if (!vpn.connected) {
				error(`disconnected from vpn: ${stdout}${stderr}`);
			}
		});
	}

	async function getLocation() {
		let json;
		try {
			json = await (await get("https://ipapi.co/json/")).json();
		} catch (err) {
			error("error fetching from ipapi.co: %O", err);
			return;
		}

		if (json.city) {
			const region =
				json.region.length > 12 ? json.region_code : json.region;
			vpn.location = `${json.city}, ${region}`;
		}
	}

	getStatus();
	getLocation();

	const interval = setInterval(getStatus, 5000);
	onDestroy(() => {
		clearInterval(interval);
	});
</script>

{#if vpn.connected !== null}
	<hr class="m-8" />

	<div class="flex flex-col gap-2">
		<div class="text-3xl">VPN Status</div>

		<div class="text-6xl">
			{#if vpn.connected}
				<span class="text-green-400">CONNECTED</span>
			{:else}
				<span class="text-red-400">DISCONNECTED</span>
			{/if}
		</div>

		{#if vpn.location}
			<div class="text-4xl">{vpn.location}</div>
		{/if}
	</div>
{/if}
