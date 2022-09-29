<script lang="ts">
	import Carousel from "svelte-carousel";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import GamepadButton from "../GamepadButton/index.svelte";
	import Header from "../Header/index.svelte";
	import playState from "../Play/State";
	import search, { Source } from "../SearchResults/search";
	import state from "./State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { error, log } from "../log";
	import { onDestroy, onMount } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";
	import FaDownload from "svelte-icons/fa/FaDownload.svelte";

	const title = cache.tv[$params.id];
	let seasons = state.seasons;

	if (seasons.length) {
		onMount(update);
	} else {
		const interval = setInterval(() => {
			if (state.seasons.length) {
				seasons = state.seasons;
				clearInterval(interval);
				setTimeout(update);
			}
		}, 50);
	}

	let seasonIndex = 0;
	$: activeSeason = seasons[seasonIndex];
	$: activeEpisode = activeSeason?.episodes[activeSeason.activeEpisode];
	let seasonsEle: HTMLDivElement;

	function gamepadHandler(button: string) {
		if (button === "B") {
			history.back();
			return;
		}

		if (!seasons.length) {
			return;
		}

		switch (button) {
			case "A":
				if (magnets[activeSeason.number]?.[activeEpisode.number]) {
					playState.magnet =
						magnets[activeSeason.number][activeEpisode.number];
					location.href = `#/tv/${title.id}/play`;
				}
				return;
			case "left":
				if (seasonIndex > 0) {
					carousel.goTo(seasonIndex - 1);
				} else {
					carousel.goTo(seasons.length - 1);
				}
				break;
			case "right":
				if (seasonIndex < seasons.length - 1) {
					carousel.goTo(seasonIndex + 1);
				} else {
					carousel.goTo(0);
				}
				break;
			case "up":
				if (activeSeason.activeEpisode > 0) {
					activeSeason.activeEpisode--;
				}
				break;
			case "down":
				if (
					activeSeason.activeEpisode <
					activeSeason.episodes.length - 1
				) {
					activeSeason.activeEpisode++;
				}
				break;
		}

		setTimeout(update);
	}

	const magnets: {
		[season: number]: { [episode: number]: null | string };
	} = {};
	let controller: AbortController;
	async function update() {
		seasonsEle.scrollTo(activeSeason.ele.offsetLeft - 16, 0);
		activeSeason.episodesEle.scrollTo(0, activeEpisode.ele.offsetTop - 20);

		const season = activeSeason;
		const episode = activeEpisode;
		controller?.abort();
		controller = new AbortController();
		try {
			if (!magnets[season.number]?.[episode.number]) {
				const sources = (
					await Promise.all([
						cachedSearch(`${title.title} Season ${season.number}`),
						cachedSearch(
							`${title.title} S${String(season.number).padStart(
								2,
								"0"
							)}`
						),
						cachedSearch(
							`${title.title} S${String(season.number).padStart(
								2,
								"0"
							)}E${String(episode.number).padStart(2, "0")}`
						),
					])
				)
					.flat()
					.filter(
						(source) =>
							source.seasons?.includes(season.number) &&
							[episode.number, null].includes(source.episode)
					)
					.sort((a, b) => b.score - a.score);

				const source = sources[0];
				log("%O", source);
				if (!magnets[season.number]) {
					magnets[season.number] = {};
				}
				if (source?.seeders >= 5) {
					const magnet = await source.getMagnet();
					if (source.episode) {
						magnets[season.number][episode.number] = magnet;
					} else {
						for (const seasonNum of source.seasons) {
							if (!magnets[seasonNum]) {
								magnets[seasonNum] = {};
							}

							for (let i = 1; i <= season.episodes.length; i++) {
								if (!magnets[seasonNum][i]) {
									magnets[seasonNum][i] = magnet;
								}
							}
						}
					}
				} else {
					magnets[season.number][episode.number] = null;
				}
			}
		} catch (err) {
			if (!(err instanceof DOMException)) {
				error("search err: %O", err);
			}
		}
	}

	const searchCache: { [query: string]: Source[] } = {};
	async function cachedSearch(query: string): Promise<null | Source[]> {
		if (!searchCache[query]) {
			searchCache[query] = await search(query, controller.signal);
		}
		return searchCache[query];
	}

	let carousel: Carousel;

	function retry(e: any) {
		e.srcElement.src = e.srcElement.src;
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen flex flex-col">
	<div class="px-48">
		<Header title={title.title} back />
	</div>

	{#if seasons.length}
		<div class="px-48 min-h-[108px] flex flex-col my-2">
			<div class="text-3xl text-ellipsis overflow-hidden grow clamp-3">
				{activeEpisode.overview}
			</div>
		</div>

		<div class="px-48">
			<div
				class="flex gap-8 overflow-scroll scroll-smooth pt-4 pb-5 px-3 shrink-0 relative"
				bind:this={seasonsEle}
			>
				{#each seasons as season, i}
					<div
						class="season text-3xl text-black bg-[#eee] rounded-full p-4 shrink-0 relative drop-shadow"
						class:active={seasonIndex === i}
						bind:this={season.ele}
					>
						Season {season.number}
					</div>
				{/each}
			</div>
		</div>

		<Carousel
			arrows={false}
			dots={false}
			duration={250}
			bind:this={carousel}
			on:pageChange={(e) => {
				seasonIndex = e.detail;
			}}
		>
			{#each seasons as season, i}
				<div
					class="flex px-48 flex-col gap-12 overflow-scroll scroll-smooth pt-5 relative pb-[13rem] h-[66vh]"
					bind:this={season.episodesEle}
				>
					{#each season.episodes as episode, j}
						<div
							class="episode flex bg-[#eee] rounded-xl text-black overflow-hidden text-5xl min-h-[127px] items-center relative white-shadow"
							class:active={i === seasonIndex &&
								j === activeSeason.activeEpisode}
							bind:this={episode.ele}
						>
							{#if episode.still && Math.abs(seasonIndex - i) < 2}
								<div
									class="max-h-[127px] min-w-[277px] max-w-[277px] overflow-hidden flex items-center justify-start drop-shadow"
								>
									<img
										alt=""
										src="https://image.tmdb.org/t/p/w227_and_h127_bestv2{episode.still}"
										class="inline-block min-w-[227px]"
										on:error={retry}
									/>
								</div>
							{/if}

							<div class="ml-4 grow">
								<span class="text-slate-600 inline-block mr-2">
									E{String(episode.number).padStart(2, "0")}
								</span>
								<span class:text-4xl={episode.name.length > 40}>
									{episode.name}
								</span>
							</div>

							{#if i === seasonIndex && j === activeSeason.activeEpisode}
								<div
									class="mr-8 h-full flex items-center justify-center min-w-[146px]"
								>
									{#if magnets[season.number] && magnets[season.number][episode.number] !== undefined}
										{#if magnets[season.number][episode.number]}
											<div class="h-1/2 flex gap-8">
												<div class="relative h-full">
													<GamepadButton button="X" />
													<FaDownload />
												</div>
												<div class="relative h-full">
													<GamepadButton button="A" />
													<FaPlay />
												</div>
											</div>
										{:else if magnets[season.number][episode.number] === null}
											Unavailable
										{/if}
									{:else}
										<Circle2 />
									{/if}
								</div>
							{/if}
						</div>
					{/each}
				</div>
			{/each}
		</Carousel>
	{:else}
		<div class="flex justify-center items-center h-full">
			<Circle2 size={256} />
		</div>
	{/if}
</div>

<style>
	.clamp-3 {
		display: -webkit-box;
		-webkit-line-clamp: 3;
		-webkit-box-orient: vertical;
	}

	.season,
	.episode,
	img {
		transition: transform 500ms 50ms;
	}

	img,
	.active {
		transform: scale(1.15);
	}

	.active img {
		transform: scale(1);
	}
</style>