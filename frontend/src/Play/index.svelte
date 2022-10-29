<script lang="ts">
	const { params } = require("svelte-hash-router");
	import Header from "../Header/index.svelte";
	import child_process from "child_process";
	import rootState from "../State";
	import state from "./State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { error, log } from "../log";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	const title = $params.type
		? cache[$params.type][$params.id].title
		: unescape($params.query);
	const overlay = child_process.spawn("atlas-overlay", {
		stdio: "inherit",
	});

	overlay.on("error", (err: Error) => {
		error("%O", err);
	});

	overlay.once("exit", (code) => {
		log("overlay exit code: %O", code);
	});

	rootState.torrentd.send({
		message: "play",
		magnet: state.magnet,
		file: state.file,
	});

	rootState.torrentd.on("message", msgHandler);

	function gamepadHandler(button: string) {
		if (button === "B") {
			overlay.kill();
			rootState.torrentd.send({ message: "stop" });
			history.back();
			return;
		}
	}

	function msgHandler(msg: any) {
		if (msg.message === "player_closed") {
			history.back();
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
		rootState.torrentd.off("message", msgHandler);
	});
</script>

<div class="h-screen flex flex-col px-48">
	<Header back {title} />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
