<script lang="ts">
	import Carousel from "svelte-carousel";
	import Header from "../Header/index.svelte";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache } from "../db";
	import { fetchJSON } from "..";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	interface Season {
		number: number;
		episodes: Episode[];
		activeEpisode: number;
		ele: HTMLDivElement;
		episodesEle: HTMLDivElement;
	}

	interface Episode {
		number: number;
		date: Date;
		name: string;
		overview: string;
		runtime: number;
		still: string;
		ele: HTMLDivElement;
	}

	const title = cache.tv[$params.id];

	let ready = false;
	let seasons: Season[] = [];
	let seasonIndex = 0;
	$: activeSeason = seasons[seasonIndex];
	$: activeEpisode = activeSeason?.episodes[activeSeason.activeEpisode];
	let seasonsEle: HTMLDivElement;
	(async () => {
		for (let i = 0, keys = 20; keys === 20; i++) {
			let append = Array(20)
				.fill(null)
				.map((_, j) => `season/${i * 20 + j + 1}`)
				.join(",");
			const json = await fetchJSON(
				`https://api.themoviedb.org/3/tv/${title.id}?api_key=${process.env.TMDB_KEY}&append_to_response=${append}`
			);
			keys = Object.keys(json).filter((key) => key.startsWith("season/"))
				.length;

			for (let j = 0; j < keys; j++) {
				const season = json[`season/${i * 20 + j + 1}`];
				if (season.episodes.length) {
					seasons.push({
						number: season.season_number,
						episodes: season.episodes.map((episode: any) => ({
							number: episode.episode_number,
							date: new Date(episode.air_date),
							name: episode.name,
							overview: episode.overview,
							runtime: episode.runtime,
							still: episode.still_path,
						})),
						activeEpisode: 0,
						ele: null,
						episodesEle: null,
					});
				}
			}
		}

		seasons = seasons;
		ready = true;
	})();

	function gamepadHandler(button: string) {
		switch (button) {
			case "A":
				location.href = `#/results/${escape(title.title)
					.replace(/\./g, "%2E")
					.replace(
						/\+/g,
						"%2B"
					)}%20${title.released?.getFullYear()} s${String(
					activeSeason.number
				).padStart(2, "0")}e${String(activeEpisode.number).padStart(
					2,
					"0"
				)}`;
				return;
			case "B":
				history.back();
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

		setTimeout(scroll);
	}

	function scroll() {
		seasonsEle.scrollTo(activeSeason.ele.offsetLeft - 16, 0);
		activeSeason.episodesEle.scrollTo(0, activeEpisode.ele.offsetTop - 20);
	}

	let carousel: Carousel;

	function retry(e) {
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

	{#if ready}
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

							<div class="ml-4">
								<span class="text-slate-600 mr-2 inline-block">
									E{String(episode.number).padStart(2, "0")}
								</span>
								<span class:text-4xl={episode.name.length > 40}>
									{episode.name}
								</span>
							</div>
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

	img {
		transform: scale(1.15);
	}

	.active {
		transform: scale(1.15);
	}

	.active img {
		transform: scale(1);
	}
</style>
