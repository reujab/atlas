<script>
	import Row from "./Row";
	import Header from "../Header";
	import { getTrending, getTopRated } from "../db";

	let rows = [new Row("Trending"), new Row("Top rated")];
	const cols = 5;

	getTrending().then((trending) => {
		rows[0].titles = trending;
	});

	getTopRated().then((topRated) => {
		rows[1].titles = topRated;
	});
</script>

<div class="h-screen px-48 bg-white">
	<Header title="Movies" back="/" search="/movies/search" />

	{#each rows as row}
		<h2 class="text-7xl mb-10">{row.name}</h2>
		<div class="flex justify-between mb-10">
			{#each row.titles
				// wrap around
				.concat(row.titles.slice(0, cols))
				.slice(row.index, row.index + cols) as title}
				<a
					key={title.id}
					href="#/movies/details/{title.id}"
					class="shrink-0 w-64"
				>
					<img src="posters/{title.id}" alt={title.title} />
				</a>
			{/each}
		</div>
	{/each}
</div>
