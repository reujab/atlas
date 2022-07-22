<script lang="ts">
	import Header from "../Header";
	import prettyBytes from "pretty-bytes";
	import { params } from "svelte-hash-router";
	import { Circle2 } from "svelte-loading-spinners";
	import { subscribe, unsubscribe } from "../gamepad";
	import { onDestroy } from "svelte";
	import child_process from "child_process";

	interface Source {
		info_hash: string;
		name: string;
		seeders: number;
		leechers: number;
		size: number;
	}

	const query = unescape($params.query);
	console.log(query);

	let sources: Source[] = [];
	fetch(
		`https://apibay.org/q.php?q=${encodeURIComponent(
			query.replace(/['"]/g, "").replace(/\./g, " ")
		)}&cat=200`
	).then((res) => {
		res.json().then((res) => {
			sources = res;
		});
	});

	let activeSource = 0;

	function play(source: Source) {
		sources = [];

		const magnet = `magnet:?xt=urn:btih:${
			source.info_hash
		}&dn=${encodeURIComponent(
			source.name
		)}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2710%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2780%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2730%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=http%3A%2F%2Fp4p.arenabg.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce`;

		const webtorrent = child_process.spawn("webtorrent", [
			"download",
			magnet,
			"--mpv",
		]);

		let started = false;

		async function checkPosition() {
			const child = child_process.spawn("playerctl", ["position"]);
			child.stdout.on("data", (data) => {
				console.log(data.toString());
				const position = Number(data.toString().trim());
				if (position > 0.1) {
					started = true;
					const overlay = child_process.spawn("overlay", {
						detached: true,
						stdio: "ignore",
					});
					overlay.on("exit", () => {
						webtorrent.kill();
					});
				}
			});
			child.on("exit", () => {
				if (!started) {
					checkPosition();
				}
			});
		}

		checkPosition();
	}

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
