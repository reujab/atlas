<script lang="ts">
	import Button from "./Button.svelte";
	import FaDownload from "svelte-icons/fa/FaDownload.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import FaYoutube from "svelte-icons/fa/FaYoutube.svelte";
	import Header from "../Header/index.svelte";
	import Rating from "./Rating.svelte";
	import getSeasons from "../Seasons/getSeasons";
	import playState from "../Play/State";
	import search, { Source } from "../SearchResults/search";
	import seasonsState from "../Seasons/State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, genres } from "../db";
	import { error, log } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	interface IButton {
		hidden?: boolean
		icon: any
		title: string
		onClick: () => void
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

	playState.file = null;
	playState.magnet = null;
	if (title.type === "movie") {
		search(
			`${title.title} ${
				title.released ? title.released.getFullYear() : ""
			}`,
			"movie"
		)
			.then((sources: Source[]) => {
				log("source: %O", sources[0]);
				if (sources[0]?.seeders >= 10) {
					sources[0].getMagnet().then((magnet) => {
						playState.file = null;
						playState.magnet = magnet;
						buttons[0].icon = FaPlay;
						buttons[1].icon = FaDownload;
					});
				} else {
					buttons[0].title = "Unavailable";
					buttons[0].icon = null;
					buttons[1].hidden = true;
				}
			})
			.catch((err) => {
				error("search err: %O", err);
				buttons[0].title = "Error";
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
				error("%O", err);
			});
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen px-48 flex flex-col">
	<Header title={title.title} back />

	<div class="flex grow items-center">
		<div class="flex gap-4 my-4">
			<div class="shrink-0 flex flex-col gap-4">
				<img
					src="file:///{process.env
						.POSTERS_PATH}/{title.type}/{title.id}"
					alt="Poster"
					class="rounded-md white-shadow"
				/>

				<span class="text-3xl text-center">{releaseDate}</span>
			</div>

			<div>
				<h3 class="text-4xl mb-8">
					{#if title.rating}
						<Rating rating={title.rating} />
					{/if}
					<span class:ml-2={title.rating}>
						{title.genres
							?.map((genre) => genres[genre])
							.join(" • ")}
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
