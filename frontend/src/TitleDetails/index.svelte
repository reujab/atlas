<script lang="ts">
	import Button from "./Button.svelte";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import FaCheck from "svelte-icons/fa/FaCheck.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import FaPlus from "svelte-icons/fa/FaPlus.svelte";
	import FaYoutube from "svelte-icons/fa/FaYoutube.svelte";
	import Header from "../Header/index.svelte";
	import Poster from "../Poster";
	import Rating from "./Rating.svelte";
	import playState from "../Play/State";
	import seasonsState from "../Seasons/State";
	import titlesState from "../Titles/State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, getSeasons, Season, TitleType } from "../db";
	import { error, log } from "../log";
	import { get } from "..";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	interface IButton {
		icon: any;
		title: string;
		onClick: () => void;
	}

	const type = $params.type as TitleType;
	const title = cache[type][$params.id];
	const buttons: IButton[] = [];
	const rows = titlesState[type].rows;
	const seasons = seasonsState.seasons;
	let activeButton = 0;
	let inList = $rows[0].titles.includes(title);

	log("title: %O", title);

	if (type === "movie") {
		buttons.push({
			icon: Circle2,
			title: "Play",
			onClick() {
				if (playState.magnet) {
					location.href = `#/movie/${title.id}/play`;
				}
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

	buttons.push({
		icon: inList ? FaCheck : FaPlus,
		title: "Add to list",
		onClick() {
			// eslint-disable-next-line no-shadow
			titlesState[type].rows.update((rows) => {
				const myList = rows[0];
				const index = myList.titles.indexOf(title);
				if (index === -1) {
					myList.titles.unshift(title);
					inList = true;
				} else {
					myList.titles.splice(index, 1);
					inList = false;
				}
				buttons[1].icon = inList ? FaCheck : FaPlus;
				return rows;
			});
		},
	});

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
			})
			.catch((err) => {
				console.error(err);
				buttons[0].title = "Unavailable";
				buttons[0].icon = null;
			});
	}

	// preload seasons
	const imgCache = [];
	if (title.type === "tv" && !$seasons.length) {
		getSeasons(title)
			.then((s: Season[]) => {
				$seasons = s;

				// preload first season stills
				for (const episode of $seasons[0]?.episodes || []) {
					if (!episode.still) continue;
					const img = new Image();
					img.src = `https://image.tmdb.org/t/p/w227_and_h127_bestv2${episode.still}`;
					imgCache.push(img);
				}
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
			<div>
				<Button
					icon={button.icon}
					text={button.title}
					active={i === activeButton}
				/>
			</div>
		{/each}
	</div>
</div>
