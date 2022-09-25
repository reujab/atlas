<script lang="ts">
	import Header from "../Header/index.svelte";
	import child_process from "child_process";
	import spawnOverlay from "../spawnOverlay";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const title = cache[$params.type][$params.id];
	const mpv = child_process.spawn(
		"mpv",
		["--audio-device=alsa/hdmi:CARD=PCH,DEV=0", `ytdl://${title.trailer}`],
		{ stdio: "inherit" }
	);
	const cancelOverlay = spawnOverlay(() => {
		if (location.hash.includes("/trailer")) {
			history.back();
		}
	});

	function gamepadHandler(button: string) {
		if (button === "B") {
			mpv.kill();
			cancelOverlay();
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
