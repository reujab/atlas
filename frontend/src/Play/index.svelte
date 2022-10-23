<script lang="ts">
	const { params } = require("svelte-hash-router");
	import Header from "../Header/index.svelte";
	import rootState from "../State";
	import spawnOverlay from "../spawnOverlay";
	import state from "./State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	const title = $params.type
		? cache[$params.type][$params.id].title
		: unescape($params.query);
	const cancelOverlay = spawnOverlay();

	function gamepadHandler(button: string) {
		if (button === "B") {
			cancelOverlay();
			rootState.torrentdSocket.write(JSON.stringify({ message: "stop" }));
			history.back();
			return;
		}
	}

	rootState.torrentdSocket.write(
		JSON.stringify({
			message: "play",
			magnet: state.magnet,
			file: state.file,
		})
	);

	rootState.torrentdSocket.on("data", dataHandler);

	function dataHandler(chunk: Buffer) {
		const data = JSON.parse(chunk.toString());
		if (data.message === "player_closed") {
			history.back();
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
		rootState.torrentdSocket.off("data", dataHandler);
	});
</script>

<div class="h-screen flex flex-col px-48">
	<Header back {title} />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
