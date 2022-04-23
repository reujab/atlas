<script>
	import Header from "../Header";
	import prettyBytes from "pretty-bytes";
	import { invoke } from "@tauri-apps/api";
	import { params } from "svelte-hash-router";
	import { Circle2 } from "svelte-loading-spinners";
	import { subscribe, unsubscribe } from "../gamepad.js";
	import { onDestroy } from "svelte";

	const query = unescape($params.query);

	let sources = [];
	invoke("get_sources", {
		query: encodeURIComponent(query.replace(/['".]/g, "")),
	}).then((res) => {
		sources = res;
	});

	let activeSource = 0;

	function play(source) {
		invoke("play", {
			hash: source.info_hash,
			name: encodeURIComponent(source.name),
		});
	}

	function gamepadHandler(button) {
		if (button === "B") {
			history.back();
			return;
		}

		if (!sources.length) {
			return;
		}

		switch (button) {
			case "A":
				play(sources[activeSource]);
				break;
			case "B":
				history.back();
				break;
			case "up":
				if (activeSource > 0) {
					activeSource--;
				}
				break;
			case "down":
				if (activeSource < sources.length - 1) {
					activeSource++;
				}
				break;
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen px-48 bg-white flex flex-col">
	<Header title={query} back />

	{#if sources.length}
		<div class="flex gap-8 flex-col text-2xl">
			{#each sources.slice(activeSource) as source, i}
				<div
					class="source rounded-lg bg-slate-200 border-4 border-transparent p-4 flex cursor-pointer drop-shadow-sm"
					class:active={i === 0}
					on:click={() => play(source)}
				>
					{source.name}
					<div class="grow" />
					{`${source.seeders}|${source.leechers}`}
					{" • "}
					{prettyBytes(Number(source.size))}
				</div>
			{/each}
		</div>
	{:else}
		<div class="flex justify-center items-center h-full">
			<Circle2 size={256} />
		</div>
	{/if}
</div>

<style>
	.source.active,
	.source:hover {
		border-color: black !important;
	}
</style>
