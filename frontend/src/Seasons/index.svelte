<script lang="ts">
	import Carousel from "svelte-carousel";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import GamepadButton from "../GamepadButton.svelte";
	import Header from "../Header/index.svelte";
	import playState from "../Play/State";
	import state from "./State";
	import { Circle2 } from "svelte-loading-spinners";
	import { cache, Season, progress, getMagnet } from "../db";
	import { onDestroy, onMount } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";
	import { log } from "../log";

	const title = cache.tv[$params.id];
	let seasons = state.seasons;
	let carousel: any;
	let seasonsEle: HTMLDivElement;
	$: activeSeason = $seasons[state.seasonIndex];
	$: activeEpisode = activeSeason?.episodes[activeSeason.activeEpisode];

	if ($seasons.length) {
		onMount(init);
	} else {
		const unsub = seasons.subscribe((s) => {
			if (!s.length) return;

			unsub();
			setTimeout(init);
		});
	}

	function gamepadHandler(button: string): void {
		if (button === "home") {
			location.hash = "#/home";
			return;
		}

		if (button === "B") {
			history.back();
			return;
		}

		if (!$seasons.length) return;

		switch (button) {
			case "A":
				if (!activeEpisode.magnet) {
					return;
				}

				playState.magnet = activeEpisode.magnet;
				playState.season = activeSeason.number;
				playState.episode = activeEpisode.number;
				location.href = `#/tv/${title.id}/play`;
				return;
			case "left":
				if (state.seasonIndex > 0) {
					carousel.goTo(state.seasonIndex - 1);
				} else {
					carousel.goTo($seasons.length - 1);
				}
				break;
			case "right":
				if (state.seasonIndex < $seasons.length - 1) {
					carousel.goTo(state.seasonIndex + 1);
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

	function init(): void {
		if ($progress[title.type][title.id]) {
			const pair = String($progress[title.type][title.id])
				.split("-")
				.map(Number);

			state.seasonIndex = $seasons.findIndex((s) => s.number === pair[0]);
			$seasons[state.seasonIndex].activeEpisode = $seasons[
				state.seasonIndex
			].episodes.findIndex((e) => e.number === pair[1]);
			setTimeout(() => {
				carousel.goTo(state.seasonIndex);
			});
		}
		setTimeout(update);
	}

	async function update(): Promise<void> {
		seasonsEle.scrollTo(activeSeason.ele?.offsetLeft - 16, 0);
		activeSeason.episodesEle?.scrollTo(
			0,
			activeEpisode.ele?.offsetTop - 20
		);

		const season = activeSeason;
		const episode = activeEpisode;
		const source = await getMagnet(
			title.type,
			title.title,
			season.number,
			episode.number
		);

		seasons.update((): Season[] => {
			if (source?.seasons) {
				for (const seasonNum of source.seasons) {
					// eslint-disable-next-line no-shadow
					for (const episode of $seasons.find(
						(s) => s.number === seasonNum
					).episodes) {
						episode.magnet = source.magnet;
					}
				}
			} else {
				activeEpisode.magnet = source ? source.magnet : null;
			}

			return $seasons;
		});
	}

	function retry(e: any): void {
		log("retrying");
		e.srcElement.src = e.srcElement.src;
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<ErrorBanner />

<div class="h-screen flex flex-col">
	<div class="px-48">
		<Header title={title.title} back />
	</div>

	{#if $seasons.length}
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
				{#each $seasons as season, i}
					<div
						class="season text-3xl text-black bg-[#eee] rounded-full p-4 shrink-0 relative drop-shadow"
						class:active={state.seasonIndex === i}
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
			initialPageIndex={state.seasonIndex}
			bind:this={carousel}
			on:pageChange={(e) => {
				state.seasonIndex = e.detail;
			}}
		>
			{#each $seasons as season, i}
				<div
					class="flex px-48 flex-col gap-12 overflow-scroll scroll-smooth pt-5 relative pb-[13rem] h-[66vh]"
					bind:this={season.episodesEle}
				>
					{#each season.episodes as episode, j}
						<div
							class="episode flex bg-[#eee] rounded-xl text-black overflow-hidden text-5xl min-h-[127px] items-center relative white-shadow"
							class:active={i === state.seasonIndex &&
								j === activeSeason.activeEpisode}
							bind:this={episode.ele}
						>
							{#if episode.still && Math.abs(state.seasonIndex - i) < 2}
								<div
									class="max-h-[127px] overflow-hidden flex items-center justify-start drop-shadow relative mr-6"
								>
									<img
										alt=""
										src="https://image.tmdb.org/t/p/w227_and_h127_bestv2{episode.still}"
										class="inline-block"
										on:error={retry}
									/>
									<div
										class="absolute bottom-0 left-0 right-0 h-1"
									>
										<div
											style="width: {Number(
												$progress[title.type][
													`${title.id}-${season.number}-${episode.number}`
												] || 0
											) * 100}%"
											class="bg-red-500 h-full"
										/>
									</div>
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

							<div
								class="mr-8 h-full flex items-center justify-center min-w-[146px]"
							>
								{#if i === state.seasonIndex && j === activeSeason.activeEpisode}
									{#if episode.magnet !== undefined}
										{#if episode.magnet === null}
											Unavailable
										{:else}
											<div class="h-1/2 flex gap-8">
												<div class="relative h-full">
													<GamepadButton button="A" />
													<FaPlay />
												</div>
											</div>
										{/if}
									{:else}
										<Circle2 />
									{/if}
								{/if}
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

	img,
	.active {
		transform: scale(1.15);
	}

	.active img {
		transform: scale(1);
	}
</style>
