<script lang="ts">
	import Header from "../Header";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { params } from "svelte-hash-router";
	import child_process from "child_process";
	import spawnOverlay from "../spawnOverlay";

	const title = cache[$params.id];

	child_process.spawn(
		"mpv",
		["--audio-device=alsa/hdmi:CARD=PCH,DEV=0", `ytdl://${title.trailer}`],
		{ stdio: "inherit" }
	);

	spawnOverlay(() => {
		if (location.hash.includes("/trailer")) {
			history.back();
		}
	});
</script>

<div class="h-screen px-48 bg-white flex flex-col">
	<Header title={title.title} back />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
