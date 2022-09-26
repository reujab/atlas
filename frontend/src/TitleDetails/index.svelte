<script lang="ts">
	import Button from "./Button.svelte";
	import FaDownload from "svelte-icons/fa/FaDownload.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import FaYoutube from "svelte-icons/fa/FaYoutube.svelte";
	import Header from "../Header/index.svelte";
	import Rating from "./Rating.svelte";
	import getSeasons from "../Seasons/getSeasons";
	import seasonsState from "../Seasons/State";
	import { cache, genres } from "../db";
	import { error, log } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	interface IButton {
		title: string;
		href: string;
		icon: any;
	}

	const title = cache[$params.type][$params.id];
	log("%O", title);

	const buttons: IButton[] = [];
	let activeButton = 0;

	if ($params.type === "movie") {
		buttons.push({
			title: "Play",
			href: `#/results/${escape(title.title)
				.replace(/\./g, "%2E")
				.replace(/\+/g, "%2B")}%20${title.released?.getFullYear()}`,
			icon: FaPlay,
		});

		buttons.push({
			title: "Download",
			href: `#/movie/${title.id}/download`,
			icon: FaDownload,
		});
	} else {
		buttons.push({
			title: "View",
			href: `#/tv/${title.id}/view`,
			icon: FaPlay,
		});
	}

	if (title.trailer) {
		buttons.push({
			title: "Watch trailer",
			href: `#/${title.type}/${title.id}/trailer`,
			icon: FaYoutube,
		});
	}

	const releaseDate = title.released?.toLocaleDateString(undefined, {
		day: "numeric",
		month: "long",
		year: "numeric",
	});

	function gamepadHandler(button: string) {
		switch (button) {
			case "A":
				location.href = buttons[activeButton].href;
				break;
			case "B":
				seasonsState.seasons = [];
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
			<a href={button.href}>
				<Button
					icon={button.icon}
					text={button.title}
					active={i === activeButton}
				/>
			</a>
		{/each}
	</div>
</div>
