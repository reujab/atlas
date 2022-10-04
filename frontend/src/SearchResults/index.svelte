<script lang="ts">
	const { params } = require("svelte-hash-router");
	import Header from "../Header/index.svelte";
	import getFiles, { File } from "./getFiles";
	import playState from "../Play/State";
	import prettyBytes from "pretty-bytes";
	import search, { episodeRegex, Source } from "./search";
	import { Circle2 } from "svelte-loading-spinners";
	import { log, error } from "../log";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	const query = unescape($params.query);
	let container: HTMLDivElement;
	let sourceIndex = 0;
	let sources: Source[] | File[] = [];
	let showingFiles = false;
	$: activeSource = sources[sourceIndex];

	log(query);
	search(query)
		.then((res) => {
			sources = res;
		})
		.catch((err) => {
			error("search error: %O", err);
		});

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
				const source = activeSource;
				const playHref = `#/results/${query}/play`;
				sources = [];

				if (showingFiles) {
					playState.file = (source as File).index;
					location.href = playHref;
					return;
				}

				(source as Source).getMagnet().then((magnet) => {
					playState.magnet = magnet;

					// test if source has a season with no episode
					const match = source.name.match(episodeRegex);
					if (match?.[1] && !match?.[3]) {
						showingFiles = true;
						sources = [];
						getFiles(magnet)
							.then((files) => {
								sourceIndex = 0;
								sources = files;
							})
							.catch((err) => {
								error("getFiles err: %O", err);
								history.back();
								return;
							});
					} else {
						playState.file = null;
						location.href = playHref;
					}
				});
				break;
			case "up":
				if (sourceIndex > 0) {
					sourceIndex--;
				}
				break;
			case "down":
				if (sourceIndex < sources.length - 1) {
					sourceIndex++;
				}
				break;
		}

		setTimeout(() => {
			container?.scrollTo(
				0,
				(activeSource as Source)?.element.offsetTop - 16
			);
		});
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
					class:active={i === sourceIndex}
					bind:this={source.element}
				>
					{source.name}
					<div class="grow" />
					{#if source.leechers !== undefined}
						{`${source.seeders} | ${source.leechers}`}
						{" • "}
						{prettyBytes(Number(source.size))}
					{:else}
						{source.size}
					{/if}
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
