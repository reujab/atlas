<script lang="ts">
	import Header from "../Header";
	import Row from "./Row";
	import { subscribe, unsubscribe } from "../gamepad";
	import {
		getTrending,
		getTopRated,
		genres,
		sortedGenres,
		getTitlesWithGenre,
	} from "../db";
	import state from "./State";
	import { onDestroy, onMount } from "svelte";

	$: activeTitle =
		state.rows[state.activeRow].titles[
			state.rows[state.activeRow].activeCol
		];

	let rowsEle: HTMLDivElement;

	function gamepadHandler(button: string) {
		const row = state.rows[state.activeRow];
		const title = row.titles[row.activeCol];
		switch (button) {
			case "A":
				location.hash = `#/movies/details/${title.id}`;
				break;
			case "B":
				history.back();
				break;
			case "up":
				state.activeRow =
					(state.rows.length + state.activeRow - 1) %
					state.rows.length;
				break;
			case "down":
				state.activeRow =
					(state.rows.length + state.activeRow + 1) %
					state.rows.length;
				break;
			case "left":
				row.activeCol =
					(row.titles.length + row.activeCol - 1) % row.titles.length;
				state.rows = state.rows;
				break;
			case "right":
				row.activeCol =
					(row.titles.length + row.activeCol + 1) % row.titles.length;
				state.rows = state.rows;
				break;
		}

		scroll(row);
	}

	function scroll(row: Row) {
		const rowHeight = document.querySelector(".row").clientHeight;
		rowsEle.scrollTo(0, state.activeRow * rowHeight);

		const borderWidth = 4 * 2;
		const gap = 16;
		const colWidth =
			document.querySelector(".poster").clientWidth + borderWidth + gap;
		row.element.scrollTo(row.activeCol * colWidth, 0);
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
	onMount(() => {
		scroll(state.rows[state.activeRow]);
	});
</script>

<div class="h-screen px-48 flex flex-col">
	<Header title="Movies" back search="/movies/search" />

	<div class="min-h-[9rem] flex flex-col mb-2">
		{#if activeTitle}
			<h3 class="text-xl mb-2">
				{activeTitle.genres.map((genre) => genres[genre]).join(" • ")}
			</h3>

			<div class="text-3xl text-ellipsis overflow-hidden grow clamp-3">
				{activeTitle.overview}
			</div>
		{/if}
	</div>

	<div
		class="overflow-scroll scroll-smooth pb-[100%] flex flex-col mt-4"
		bind:this={rowsEle}
	>
		{#each state.rows as row, rowIndex}
			{#if row.titles.length}
				<div class="row">
					<h2 class="text-7xl mb-4">{row.name}</h2>
					<div
						class="flex justify-between mb-4 overflow-scroll scroll-smooth gap-4 p-4"
						bind:this={row.element}
					>
						{#each row.titles as title, colIndex}
							<a
								key={title.id}
								href="#/movies/details/{title.id}"
								class="poster shrink-0 w-[15rem] border-4 border-transparent white-shadow rounded-lg"
								class:active={rowIndex === state.activeRow &&
									colIndex ===
										state.rows[state.activeRow].activeCol}
							>
								<img
									class="rounded-md"
									src="file://{process.env
										.POSTERS_PATH}/movie/{title.id}"
									alt={title.title}
								/>
							</a>
						{/each}
					</div>
				</div>
			{/if}
		{/each}
	</div>
</div>

<style>
	.poster.active,
	.poster:hover {
		border-color: #eee;
	}

	.clamp-3 {
		display: -webkit-box;
		-webkit-line-clamp: 3;
		-webkit-box-orient: vertical;
	}
</style>
