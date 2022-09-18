<script lang="ts">
	import { onDestroy } from "svelte";
	let date = new Date();

	const interval = setInterval(() => {
		date = new Date();
	}, 50);

	onDestroy(() => {
		clearInterval(interval);
	});
</script>

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

<style>
	.mono {
		min-width: 0.6em;
		max-width: 0.6em;
		text-align: center;
	}
</style>
