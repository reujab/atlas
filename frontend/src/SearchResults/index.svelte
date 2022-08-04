<script lang="ts">
	import Header from "../Header";
	import child_process from "child_process";
	import http from "http";
	import prettyBytes from "pretty-bytes";
	import { Circle2 } from "svelte-loading-spinners";
	import { SocksProxyAgent } from "socks-proxy-agent";
	import { log, error } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";
	import FaCircleExclamation from "svelte-icons/fa/FaExclamationCircle.svelte";

	interface Source {
		info_hash: string;
		name: string;
		seeders: number;
		leechers: number;
		size: number;
	}

	const query = unescape($params.query);
	log(query);

	const agent = new SocksProxyAgent({
		hostname: "localhost",
		port: 9050,
	});

	let errorMsg = "";

	let sources: Source[] = [];
	const path = `q.php?cat=200&q=${encodeURIComponent(
		query.replace(/['"]/g, "").replace(/\./g, " ")
	)}`;
	fetch(`https://apibay.org/${path}`)
		.then((res) => {
			res.json().then((res) => {
				sources = res;
			});
		})
		.catch((err) => {
			error("%O", err);

			http.get(
				`http://piratebayo3klnzokct3wt5yyxb2vpebbuyjl7m623iaxmqhsd52coid.onion/${path}`,
				{ agent },
				(res) => {
					log("%O", res.headers);

					let data = "";
					res.on("data", (chunk) => {
						data += chunk;
					});
					res.on("end", () => {
						try {
							const json = JSON.parse(data);
							sources = json;
						} catch (err) {
							error("error parsing json: %O", err);
						}
					});
					res.on("error", (err) => {
						error("%O", err);
						errorMsg = err.toString();
					});
				}
			);
		});

	let activeSource = 0;

	function play(source: Source) {
		// shows loading icon
		sources = [];

		const magnet = `magnet:?xt=urn:btih:${
			source.info_hash
		}&dn=${encodeURIComponent(
			source.name
		)}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2710%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2780%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2730%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=http%3A%2F%2Fp4p.arenabg.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce`;

		const webtorrent = child_process.spawn(
			"webtorrent",
			[
				"download",
				magnet,
				// use mpv because it supports wayland
				"--mpv",
				"--player-args=--audio-device=alsa/hdmi:CARD=PCH,DEV=0",
			],
			{ stdio: "inherit" }
		);

		webtorrent.on("error", (err) => {
			error("%O", err);
		});

		webtorrent.on("exit", (code) => {
			if (code !== 0) {
				error("webtorrent exit code: %O", code);
			}

			if (location.hash.includes("/search/")) {
				history.back();
			}
		});

		// once mpv has started, spawn the overlay
		let started = false;
		async function checkPosition() {
			const child = child_process.spawn("playerctl", ["position"]);
			child.stdout.on("data", (data) => {
				log(data.toString());
				const position = Number(data.toString().trim());
				if (position > 0.1) {
					started = true;
					const overlay = child_process.spawn("atlas-overlay", {
						detached: true,
						stdio: "inherit",
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
			if (errorMsg) {
				errorMsg = "";
				return;
			}

			child_process.spawnSync(
				"killall",
				["overlay", "mpv", "webtorrent"],
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

	{#if errorMsg}
		<dialog class="top-0 bottom-0 drop-shadow-lg" open={Boolean(errorMsg)}>
			<h1
				class="text-6xl text-center flex border-bottom border-black mb-4"
			>
				<div class="w-16 h-16 text-red-500 inline-block">
					<FaCircleExclamation />
				</div>
				Error
			</h1>
			<div>{errorMsg}</div>
		</dialog>
	{/if}
</div>

<style>
	.source.active,
	.source:hover {
		border-color: black !important;
	}
</style>
