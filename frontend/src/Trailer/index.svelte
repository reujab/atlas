<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import childProcess from "child_process";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { error } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const title = cache[$params.type][$params.id];
	const mpv = childProcess.spawn(
		"mpv",
		[
			"--audio-device=alsa/hdmi:CARD=PCH,DEV=0",
			"--input-ipc-server=/tmp/mpv",
			`ytdl://${title.trailer}`,
		],
		{ stdio: "inherit" }
	);
	const overlay = childProcess.spawn("atlas-overlay", {
		stdio: "inherit",
	});

	overlay.on("error", (err) => {
		error("Overlay", err);
	});

	overlay.on("exit", (code) => {
		if (code) error("Overlay exit code", `${code}`);
		if (location.hash.includes("/trailer")) history.back();
	});

	function gamepadHandler(button: string): void {
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

<ErrorBanner />

<div class="h-screen px-48 flex flex-col">
	<Header title={title.title} back />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
