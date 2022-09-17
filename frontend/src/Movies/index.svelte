<script lang="ts">
	import Header from "../Header";
	import Row from "./Row";
	import { subscribe, unsubscribe } from "../gamepad";
	import { genres } from "../db";
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
			case "Y":
				location.hash = "#/search";
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

		scroll();
	}

	function scroll() {
		rowsEle.scrollTo(0, state.rows[state.activeRow].element.offsetTop);

		for (const row of state.rows) {
			row.element
				.querySelector(".posters")
				.scrollTo(
					row.element.querySelectorAll(".poster")[row.activeCol]
						?.offsetLeft - 16,
					0
				);
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
	onMount(scroll);
</script>

<div class="h-screen px-48 flex flex-col">
	<Header title="Movies" back search="/search" />

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
		class="overflow-scroll scroll-smooth pb-[100%] flex flex-col mt-4 relative"
		bind:this={rowsEle}
	>
		{#each state.rows as row, rowIndex}
			<div class="row" bind:this={row.element}>
				<h2 class="text-7xl mb-4 font-light">{row.name}</h2>
				<div
					class="posters flex mb-4 overflow-scroll scroll-smooth gap-4 p-4 relative"
				>
					{#each row.titles as title, colIndex}
						<a
							href="#/movies/details/{title.id}"
							class="poster shrink-0 w-[15rem] border-4 border-transparent white-shadow rounded-lg"
							class:active={rowIndex === state.activeRow &&
								colIndex ===
									state.rows[state.activeRow].activeCol}
						>
							<!-- svelte hack to only load the image once -->
							<!-- not sure why this works but it's simpler than running -->
							<!-- row.appendChild(title.poster) in onMount() -->
							{@html title.poster?.outerHTML}
						</a>
					{/each}
				</div>
			</div>
		{/each}
	</div>
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
