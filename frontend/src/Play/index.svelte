<script lang="ts">
	const { params } = require("svelte-hash-router");
	import Header from "../Header/index.svelte";
	import child_process from "child_process";
	import spawnOverlay from "../spawnOverlay";
	import state from "./State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { error } from "../log";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	const title = cache[$params.type][$params.id];
	const cancelOverlay = spawnOverlay();

	function gamepadHandler(button: string) {
		if (button === "B") {
			cancelOverlay?.();
			child_process.spawnSync(
				"killall",
				["overlay", "mpv", "WebTorrent"],
				{ stdio: "inherit" }
			);
			history.back();
			return;
		}
	}

	const webtorrent = child_process.spawn(
		"webtorrent",
		[
			"download",
			state.magnet,
			`--out=${process.env.HOME}/Downloads`,
			// use mpv because it supports wayland
			"--mpv",
			"--player-args=--audio-device=alsa/hdmi:CARD=PCH,DEV=0 --save-position-on-quit",
			...(state.file ? ["-s", state.file] : []),
		],
		{ stdio: "inherit" }
	);

	webtorrent.on("error", (err) => {
		error("webtorrent err: %O", err);
	});

	webtorrent.on("exit", (code) => {
		if (code) {
			error("webtorrent exit code: %O", code);
		}

		if (location.hash.endsWith("/play")) {
			history.back();
		}
	});

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen flex flex-col px-48">
	<Header back title={title.title} />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
