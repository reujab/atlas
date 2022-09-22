<script lang="ts">
	import ErrorDialog from "../ErrorDialog/index.svelte";
	import Header from "../Header/index.svelte";
	import child_process from "child_process";
	import prettyBytes from "pretty-bytes";
	import search, { Source } from "./search";
	import spawnOverlay from "../spawnOverlay";
	import { Circle2 } from "svelte-loading-spinners";
	import { log, error } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const query = unescape($params.query);
	log(query);

	let container: HTMLDivElement;
	let errorMsg = "";
	let cancelOverlay: null | (() => void) = null;

	let sources: Source[] = [];
	search(query)
		.then((res) => {
			sources = res;
		})
		.catch((err) => {
			error("search error: %O", err);
		});

	let activeSource = 0;

	async function play(source: Source) {
		// shows loading icon
		sources = [];

		const magnet = await source.getMagnet();
		const webtorrent = child_process.spawn(
			"webtorrent",
			[
				"download",
				magnet,
				`--out=${process.env.HOME}/Downloads`,
				// use mpv because it supports wayland
				"--mpv",
				"--player-args=--audio-device=alsa/hdmi:CARD=PCH,DEV=0 --save-position-on-quit",
			],
			{ stdio: "inherit" }
		);

		webtorrent.on("error", (err) => {
			error("%O", err);
		});

		webtorrent.on("exit", (code) => {
			if (code) {
				error("webtorrent exit code: %O", code);
			}

			if (location.hash.includes("/results/")) {
				history.back();
			}
		});

		cancelOverlay = spawnOverlay();
	}

	function gamepadHandler(button: string) {
		if (button === "B") {
			if (errorMsg) {
				errorMsg = "";
				return;
			}

			cancelOverlay?.();
			child_process.spawnSync(
				"killall",
				["overlay", "mpv", "WebTorrent"],
				{ stdio: "inherit" }
			);
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

<div class="h-screen bg-white flex flex-col">
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
					class="source rounded-full bg-[#eee] px-16 py-4 flex cursor-pointer white-shadow text-black"
					class:active={i === activeSource}
					on:click={() => play(source)}
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

	<ErrorDialog error={errorMsg} />
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
