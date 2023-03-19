<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import childProcess from "child_process";
	import spawnOverlay from "../spawnOverlay";
	import state from "./State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, TitleType, progress } from "../db";
	import { error, log } from "../log";
	import { get } from "..";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const type: TitleType = $params.type;
	const id = Number($params.id);
	const title = cache[type][id];
	const header = $params.type ? title.title : unescape($params.query);
	const overlay = spawnOverlay((p) => {
		const progressID =
			type === "movie"
				? String(id)
				: `${id}-${state.season}-${state.episode}`;
		$progress[type][progressID] = p;
		history.back();
	});

	let mpv: childProcess.ChildProcess;
	let cancelled = false;

	get(
		`${process.env.SEEDBOX_HOST}:8000/stream?magnet=${encodeURIComponent(
			state.magnet
		)}${state.season ? `&s=${state.season}&e=${state.episode}` : ""}`
	)
		.then(async (res) => {
			if (cancelled) {
				return;
			}

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
				history.back();
			});

			mpv.on("exit", (code, signal) => {
				log("mpv exited %O %O", code, signal);

				if (code === 1) {
					error("mpv was unable to play file");
				}
			});
		})
		.catch((err) => {
			error("Stream failed", err);
			history.back();
		});

	function gamepadHandler(button: string): void {
		if (button === "B") {
			history.back();
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		cancelled = true;
		overlay.kill();
		mpv?.kill();
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
