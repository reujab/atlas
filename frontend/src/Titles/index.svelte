<script lang="ts">
	import Circle2 from "svelte-loading-spinners/dist/ts/Circle2.svelte";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import Poster from "../Poster";
	import Row from "./Row";
	import seasonsState from "../Seasons/State";
	import store from "./State";
	import { genres, TitleType } from "../db";
	import { onDestroy, onMount } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const type = $params.type as TitleType;
	const state = store[type];
	const { ready } = state;
	const rowsStore = state.rows;
	let rows: Row[] = [];
	let rowsEle: HTMLDivElement;
	$: activeTitle =
		rows[state.activeRow]?.titles[rows[state.activeRow].activeCol];

	const unsubscribeReady = ready.subscribe((isReady) => {
		if (isReady) onReady();
	});

	function onReady(): void {
		rows = $rowsStore.filter((row) => Boolean(row.titles.length));
	}

	function gamepadHandler(button: string): void {
		if (button === "B") {
			history.back();
			return;
		}

		if (!$ready) return;

		const row = rows[state.activeRow];
		const title = row.titles[row.activeCol];
		switch (button) {
			case "A":
				seasonsState.seasonIndex = 0;
				seasonsState.seasons = [];
				location.hash = `#/${title.type}/${title.id}`;
				break;
			case "Y":
				location.hash = "#/search";
				break;
			case "up":
				state.activeRow =
					(rows.length + state.activeRow - 1) % rows.length;
				break;
			case "down":
				state.activeRow =
					(rows.length + state.activeRow + 1) % rows.length;
				break;
			case "left":
				row.activeCol =
					(row.titles.length + row.activeCol - 1) % row.titles.length;
				rows = rows;
				break;
			case "right":
				row.activeCol =
					(row.titles.length + row.activeCol + 1) % row.titles.length;
				rows = rows;
				break;
		}

		scroll();
	}

	function scroll(instant?: boolean): void {
		rowsEle?.scrollTo(0, rows[state.activeRow].element.offsetTop);

		for (const row of rows) {
			row.element?.querySelector(".posters").scrollTo({
				left:
					(row.element?.querySelectorAll(".poster")[
						row.activeCol
					] as any)?.offsetLeft - 16,
				top: 0,
				// @ts-ignore:next-line
				behavior: instant ? "instant" : "auto",
			});
		}
	}

	subscribe(gamepadHandler);
	onMount(() => {
		scroll(true);
	});
	onDestroy(() => {
		unsubscribe(gamepadHandler);
		unsubscribeReady();
	});
</script>

<ErrorBanner />

<div class="h-screen px-48 flex flex-col">
	<Header
		title={type === "movie" ? "Movies" : "TV Shows"}
		back
		search="/search"
	/>

	{#if $ready}
		<div class="min-h-[9rem] flex flex-col mb-2">
			{#if activeTitle}
				<h3 class="text-xl mb-2">
					{activeTitle.genres
						.map((genre) => genres[genre])
						.join(" • ")}
				</h3>

				<div
					class="text-3xl text-ellipsis overflow-hidden grow clamp-3"
				>
					{activeTitle.overview}
				</div>
			{/if}
		</div>

		<div
			class="overflow-scroll scroll-smooth pb-[100%] flex flex-col mt-4 relative"
			bind:this={rowsEle}
		>
			{#each rows as row, rowIndex}
				<div class="row" bind:this={row.element}>
					<h2 class="text-7xl mb-4 font-light">{row.name}</h2>
					<div
						class="posters flex mb-4 overflow-scroll scroll-smooth gap-4 px-4 py-6 relative min-h-[400px] items-center"
					>
						{#each row.titles as title, colIndex}
							<a
								href="#/{title.type}/{title.id}"
								class="poster shrink-0 w-[15rem]"
								class:active={rowIndex === state.activeRow &&
									colIndex ===
										rows[state.activeRow].activeCol}
							>
								{#if rowIndex === state.activeRow || Math.abs(colIndex - rows[rowIndex].activeCol) < 10}
									<Poster {title} />
								{/if}
							</a>
						{/each}
					</div>
				</div>
			{/each}
		</div>
	{:else}
		<div class="m-auto">
			<Circle2 size={256} />
		</div>
	{/if}
</div>

<style>
	.poster {
		transition: transform 500ms 50ms;
	}

	.poster.active {
		transform: scale(1.1);
	}

	.clamp-3 {
		display: -webkit-box;
		-webkit-line-clamp: 3;
		-webkit-box-orient: vertical;
	}
</style>
