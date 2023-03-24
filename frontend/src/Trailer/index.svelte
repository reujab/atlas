<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import childProcess from "child_process";
	import spawnOverlay from "../spawnOverlay";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";
	import { error } from "../log";

	const title = cache[$params.type][$params.id];
	const overlay = spawnOverlay();
	const mpv = childProcess.spawn(
		"mpv",
		[
			"--audio-device=alsa/hw:CARD=PCH,DEV=3",
			"--input-ipc-server=/tmp/mpv",
			"--hwdec=vaapi",
			`ytdl://${title.trailer}`,
		],
		{ stdio: "inherit" }
	);

	function gamepadHandler(button: string): void {
		if (button === "home") {
			location.hash = "#/home";
		}

		if (button === "B") {
			history.back();
		}
	}

	mpv.on("exit", (code) => {
		if (code === 1) {
			error("mpv exit code 1");
		}

		if (location.href.includes("/trailer")) history.back();
	});

	subscribe(gamepadHandler);
	onDestroy(() => {
		mpv.kill();
		overlay.kill();
		unsubscribe(gamepadHandler);
	});
</script>

<ErrorBanner />

<div class="h-screen px-48 flex flex-col">
	<Header title={title.title} back />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
