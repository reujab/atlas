<script lang="ts">
	const { params } = require("svelte-hash-router");
	import Header from "../Header/index.svelte";
	import child_process from "child_process";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";
	import { error, log } from "../log";

	const title = cache[$params.type][$params.id];
	const mpv = child_process.spawn(
		"mpv",
		[
			"--audio-device=alsa/hdmi:CARD=PCH,DEV=0",
			"--input-ipc-server=/tmp/mpv",
			`ytdl://${title.trailer}`,
		],
		{ stdio: "inherit" }
	);
	const overlay = child_process.spawn("atlas-overlay", {
		stdio: "inherit",
	});

	overlay.on("error", (err) => {
		error("%O", err);
	});

	overlay.on("exit", (code) => {
		log("overlay exit code: %O", code);

		if (location.hash.includes("/trailer")) {
			history.back();
		}
	});

	function gamepadHandler(button: string) {
		if (button === "B") {
			mpv.kill();
			overlay.kill();
			history.back();
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen px-48 flex flex-col">
	<Header title={title.title} back />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
