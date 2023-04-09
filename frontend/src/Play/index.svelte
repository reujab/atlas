<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import childProcess from "child_process";
	import spawnOverlay from "../spawnOverlay";
	import state from "./State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, TitleType, progress, initStream } from "../db";
	import { error, log } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";
	import { get } from "..";

	const type: TitleType = $params.type;
	const id = Number($params.id);
	const title = cache[type][id];
	const header = $params.type ? title.title : unescape($params.query);
	const progressID =
		type === "movie"
			? String(id)
			: `${id}-${state.season}-${state.episode}`;
	const overlay = spawnOverlay((p) => {
		$progress[type][progressID] = p;
		if (type === "tv") {
			$progress[type][String(id)] = `${state.season}-${state.episode}`;
		}
		history.back();
	});

	let mpv: childProcess.ChildProcess;
	let cancelled = false;

	initStream(state.magnet, state.season, state.episode).then((streamInfo) => {
		if (cancelled) return;

		const { video, subs } = streamInfo;
		const start = $progress[type][progressID]
			? [`--start=${$progress[type][progressID][1]}`]
			: [];
		const subFile = subs ? [`--sub-file=${subs}`] : [];
		mpv = childProcess.spawn(
			"mpv",
			[
				`--audio-device=${
					process.env.AUDIO_DEVICE || "alsa/plughw:CARD=PCH,DEV=3"
				}`,
				"--input-ipc-server=/tmp/mpv",
				"--network-timeout=300",
				"--hwdec=vaapi",
				"--vo=gpu",
				...subFile,
				...start,
				video,
			],
			{ stdio: "inherit" }
		);

		mpv.on("error", (err) => {
			console.error(err);
			history.back();
		});

		mpv.on("exit", (code, signal) => {
			log("mpv exited %O %O", code, signal);

			if (![0, 4].includes(code)) {
				error("mpv was unable to play file");
			}

			get(streamInfo.delete, {
				method: "DELETE",
			});
		});
	});

	function gamepadHandler(button: string): void {
		if (button === "home") {
			cancelled = true;
			location.hash = "#/home";
		}

		if (button === "B") {
			cancelled = true;
			history.back();
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
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
