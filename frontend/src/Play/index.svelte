<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import spawnOverlay from "../spawnOverlay";
	import state from "./State";
	import titlesState from "../Titles/State";
	import torrentd from "../torrentd";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, TitleType } from "../db";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const type: TitleType = $params.type;
	const id = Number($params.id);
	const title = cache[type][id];
	const header = $params.type ? title.title : unescape($params.query);
	const overlay = spawnOverlay(true, (progress) => {
		console.log("Progress", progress);
		title.progress = progress;
		titlesState[type].rows.update((rows) => {
			const index = rows[0].titles.indexOf(title);
			if (index === -1) {
				rows[0].titles.unshift(title);
			} else if (index !== 0) {
				rows[0].titles.unshift(rows[0].titles.splice(index, 1)[0]);
			}
			return rows;
		});
	});

	torrentd.send({
		message: "play",
		magnet: state.magnet,
		file: state.file,
	});

	torrentd.on("message", msgHandler);

	function gamepadHandler(button: string): void {
		if (button === "B") {
			overlay.kill();
			torrentd.send({ message: "stop" });
			history.back();
		}
	}

	function msgHandler(msg: any): void {
		if (msg.message === "player_closed" && location.hash.includes("/play"))
			history.back();
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
		torrentd.off("message", msgHandler);
	});
</script>

<ErrorBanner />

<div class="h-screen flex flex-col px-48">
	<Header back title={header} />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
