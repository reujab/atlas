<script>
	import Header from "../Header";
	import Row from "./Row";
	import listener from "../gamepad";
	import { getTrending, getTopRated } from "../db";
	import { onDestroy } from "svelte";

	const rows = [new Row("Trending"), new Row("Top rated")];
	const cols = 6;

	let activeRow = 0;

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
			console.log(activeRow, row.activeCol);
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
			console.log(activeRow, row.activeCol);
			console.log("-------------------");
		}
	}

	listener.on("gamepad:button", gamepadHandler);
	onDestroy(() => {
		listener.off("gamepad:button", gamepadHandler);
	});
</script>

<div class="h-screen px-48 bg-white">
	<Header title="Movies" back search="/movies/search" />

	{#each rows
		// wrap around
		.concat(rows[0])
		.slice(activeRow, activeRow + 2) as row, rowIndex}
		<h2 class="text-7xl mb-10">{row.name}</h2>
		<div class="flex justify-between mb-10">
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
</style>
