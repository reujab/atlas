<script>
	import Header from "../Header";
	import Row from "./Row";
	import listener from "../gamepad";
	import { getTrending, getTopRated, genres } from "../db";
	import { onDestroy } from "svelte";

	const rows = [new Row("Trending"), new Row("Top rated")];
	const cols = 6;

	let activeRow = 0;

	$: activeTitle = rows[activeRow].titles[rows[activeRow].activeCol];

	getTrending().then((trending) => {
		rows[0].titles = trending;
	});

	getTopRated().then((topRated) => {
		rows[1].titles = topRated;
	});

	function gamepadHandler(e) {
		if (e.detail.pressed) {
			console.log(e.detail.button);
			const row = rows[activeRow];
			const title = row.titles[row.activeCol];
			switch (e.detail.button) {
				case 0: // A button
					location.hash = `#/movies/details/${title.id}`;
					break;
				case 12: // pad up
					activeRow = (rows.length + activeRow - 1) % rows.length;
					break;
				case 13: // pad down
					activeRow = (rows.length + activeRow + 1) % rows.length;
					break;
				case 14: // pad left
					row.activeCol =
						(row.titles.length + row.activeCol - 1) %
						row.titles.length;
					rows = rows;
					break;
				case 15: // pad right
					row.activeCol =
						(row.titles.length + row.activeCol + 1) %
						row.titles.length;
					rows = rows;
					break;
			}
		}
	}

	listener.on("gamepad:button", gamepadHandler);
	onDestroy(() => {
		listener.off("gamepad:button", gamepadHandler);
	});
</script>

<div class="h-screen px-48 bg-white">
	<Header title="Movies" back search="/movies/search" />

	<div class="h-[9rem] flex flex-col mb-2">
		{#if activeTitle}
			<h3 class="text-xl mb-2">
				{activeTitle.genres.map((genre) => genres[genre]).join(" • ")}
			</h3>

			<div class="text-3xl text-ellipsis overflow-hidden grow clamp-3">
				{activeTitle.overview}
			</div>
		{/if}
	</div>

	{#each rows
		// wrap around
		.concat(rows[0])
		.slice(activeRow, activeRow + 2) as row, rowIndex}
		<h2 class="text-7xl mb-4">{row.name}</h2>
		<div class="flex justify-between mb-8">
			{#each row.titles
				// wrap around
				.concat(row.titles.slice(0, cols))
				.slice(row.activeCol, row.activeCol + cols) as title, colIndex}
				<a
					key={title.id}
					href="#/movies/details/{title.id}"
					class="poster shrink-0 w-[15rem] border-8 border-transparent rounded-lg"
					class:active={rowIndex === 0 && colIndex === 0}
				>
					<img src="posters/movies/{title.id}" alt={title.title} />
				</a>
			{/each}
		</div>
	{/each}
</div>

<style>
	.poster.active,
	.poster:hover {
		border-color: black;
	}

	.clamp-3 {
		display: -webkit-box;
		-webkit-line-clamp: 3;
		-webkit-box-orient: vertical;
	}
</style>
