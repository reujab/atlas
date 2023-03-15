<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import spawnOverlay from "../spawnOverlay";
	import state from "./State";
	import titlesState from "../Titles/State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, TitleType } from "../db";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";
	import childProcess from "child_process";
	import { get } from "..";
	import { error } from "../log";

	const type: TitleType = $params.type;
	const id = Number($params.id);
	const title = cache[type][id];
	const header = $params.type ? title.title : unescape($params.query);
	const overlay = spawnOverlay((progress) => {
		console.log("Progress", progress);
		title.progress = progress;
		// update downloaded titles
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

	let mpv: childProcess.ChildProcess;

	get(
		`${process.env.SEEDBOX_HOST}:8000/stream?magnet=${encodeURIComponent(
			state.magnet
		)}${state.season ? `&s=${state.season}&e=${state.episode}` : ""}`
	)
		.then(async (res) => {
			const stream = await res.text();

			mpv = childProcess.spawn(
				"mpv",
				[
					"--audio-device=alsa/hw:CARD=PCH,DEV=3",
					"--input-ipc-server=/tmp/mpv",
					"--save-position-on-quit",
					"--network-timeout=300",
					"--hwdec=vaapi",
					process.env.SEEDBOX_HOST + stream,
				],
				{ stdio: "inherit" }
			);

			mpv.on("error", (err) => {
				console.error(err);
			});

			mpv.on("exit", cleanup);
		})
		.catch((err) => {
			error("Stream failed", err);
			cleanup();
		});

	function gamepadHandler(button: string): void {
		if (button === "B") {
			cleanup();
		}
	}

	function cleanup(): void {
		overlay.kill();
		mpv?.kill();
		history.back();
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<ErrorBanner />

<div class="h-screen flex flex-col px-48">
	<Header back title={header} />

	<div class="flex justify-center items-center h-full">
		<Circle2 size={256} />
	</div>
</div>
