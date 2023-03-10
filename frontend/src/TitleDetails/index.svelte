<script lang="ts">
	import Button from "./Button.svelte";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import FaDownload from "svelte-icons/fa/FaDownload.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import FaYoutube from "svelte-icons/fa/FaYoutube.svelte";
	import Header from "../Header/index.svelte";
	import Poster from "../Poster";
	import Rating from "./Rating.svelte";
	import getSeasons from "../Seasons/getSeasons";
	import playState from "../Play/State";
	import seasonsState from "../Seasons/State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, genres } from "../db";
	import { error, log } from "../log";
	import { get } from "..";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	interface IButton {
		hidden?: boolean;
		icon: any;
		title: string;
		onClick: () => void;
	}

	const title = cache[$params.type][$params.id];
	const buttons: IButton[] = [];
	let activeButton = 0;

	log("title: %O", title);

	if ($params.type === "movie") {
		buttons.push({
			icon: Circle2,
			title: "Play",
			onClick() {
				if (playState.magnet) {
					location.href = `#/movie/${title.id}/play`;
				}
			},
		});

		buttons.push({
			icon: Circle2,
			title: "Download",
			onClick() {
				// TODO
			},
		});
	} else {
		buttons.push({
			icon: FaPlay,
			title: "View",
			onClick() {
				location.href = `#/tv/${title.id}/view`;
			},
		});
	}

	if (title.trailer) {
		buttons.push({
			icon: FaYoutube,
			title: "Watch trailer",
			onClick() {
				location.href = `#/${title.type}/${title.id}/trailer`;
			},
		});
	}

	const releaseDate = title.released?.toLocaleDateString(undefined, {
		day: "numeric",
		month: "long",
		year: "numeric",
	});

	function gamepadHandler(button: string): void {
		switch (button) {
			case "A":
				buttons[activeButton].onClick();
				break;
			case "B":
				history.back();
				break;
			case "left":
				if (activeButton > 0) {
					activeButton--;
				}
				break;
			case "right":
				if (activeButton < buttons.length - 1) {
					activeButton++;
				}
				break;
		}
	}

	playState.magnet = null;
	playState.season = null;
	playState.episode = null;
	if (title.type === "movie") {
		get(
			`${
				process.env.SEEDBOX_HOST
			}:8000/movie/magnet?q=${encodeURIComponent(
				`${title.title} ${
					title.released ? title.released.getFullYear() : ""
				}`
			)}`
		)
			.then(async (res) => {
				const magnet = await res.text();
				console.log(magnet);
				playState.magnet = magnet;
				playState.season = null;
				playState.episode = null;
				buttons[0].icon = FaPlay;
				buttons[1].icon = FaDownload;
			})
			.catch((err) => {
				console.error(err);
				buttons[0].title = "Unavailable";
				buttons[0].icon = null;
				buttons[1].hidden = true;
			});
	}

	// preload seasons
	if (title.type === "tv" && !seasonsState.seasons.length) {
		getSeasons(title)
			.then((seasons) => {
				seasonsState.seasons = seasons;
			})
			.catch((err) => {
				error("getSeasons error:", err);
			});
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<ErrorBanner />

<div class="h-screen px-48 flex flex-col">
	<Header title={title.title} back />

	<div class="flex grow items-center">
		<div class="flex gap-4 my-4">
			<div class="shrink-0 flex flex-col gap-4">
				<Poster {title} />

				<span class="text-3xl text-center">{releaseDate}</span>
			</div>

			<div>
				<h3 class="text-4xl mb-8">
					{#if title.rating}
						<Rating rating={title.rating} />
					{/if}
					<span class:ml-2={title.rating}>
						{title.genres?.join(" • ")}
					</span>
				</h3>

				<h3 class="text-3xl">
					{title.overview}
				</h3>
			</div>
		</div>
	</div>

	<div class="flex justify-around mb-16">
		{#each buttons as button, i}
			{#if !button.hidden}
				<div class="pointer-cursor" on:click={button.onClick}>
					<Button
						icon={button.icon}
						text={button.title}
						active={i === activeButton}
					/>
				</div>
			{/if}
		{/each}
	</div>
</div>
