<script lang="ts">
	const { params } = require("svelte-hash-router");
	import Header from "../Header/index.svelte";
	import playState from "../Play/State";
	import prettyBytes from "pretty-bytes";
	import search, { Source } from "./search";
	import { Circle2 } from "svelte-loading-spinners";
	import { log, error } from "../log";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	const query = unescape($params.query);
	log(query);

	let container: HTMLDivElement;

	let sources: Source[] = [];
	search(query)
		.then((res) => {
			sources = res;
		})
		.catch((err) => {
			error("search error: %O", err);
		});

	let activeSource = 0;

	function gamepadHandler(button: string) {
		if (button === "B") {
			history.back();
			return;
		}

		if (!sources.length) {
			return;
		}

		switch (button) {
			case "A":
				sources[activeSource].getMagnet().then((magnet) => {
					playState.file = null;
					playState.magnet = magnet;
					location.href = "#/play";
				});
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

		container.scrollTo(0, sources[activeSource]?.element.offsetTop - 16);
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen flex flex-col">
	<div class="px-48">
		<Header title={query} back />
	</div>

	{#if sources.length}
		<div
			class="flex gap-8 flex-col text-2xl relative scroll-smooth overflow-scroll px-48 mt-4 py-4 items-center"
			bind:this={container}
		>
			{#each sources as source, i}
				<div
					class="source rounded-full bg-[#eee] px-16 py-4 flex white-shadow text-black"
					class:active={i === activeSource}
					bind:this={source.element}
				>
					{source.name}
					<div class="grow" />
					{`${source.seeders} | ${source.leechers}`}
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
	.source {
		transition: min-width 500ms;
		min-width: 100%;
	}

	.source.active {
		min-width: 105%;
	}
</style>
