<script>
	import FaArrowLeft from "svelte-icons/fa/FaArrowLeft.svelte";
	import FaSearch from "svelte-icons/fa/FaSearch.svelte";
	import Database from "tauri-plugin-sql-api";
	import { invoke } from "@tauri-apps/api";
	import Row from "./Row";

	let rows = [new Row("Trending"), new Row("Top rated")];
	const cols = 5;

	invoke("get_db_url").then((db_url) => {
		Database.load(db_url).then((db) => {
			db.select(
				`
					SELECT title, id FROM movies
					ORDER BY popularity DESC NULLS LAST
					LIMIT 100
				`
			).then((res) => {
				rows[0].titles = res;
			});

			db.select(
				`
					SELECT title, id FROM movies
					WHERE votes >= 200
					ORDER BY score DESC NULLS LAST
					LIMIT 100
				`
			).then((res) => {
				rows[1].titles = res;
			});
		});
	});
</script>

<div class="h-screen px-48 bg-white">
	<h1 class="text-8xl font-light pt-10 flex items-center mb-10">
		<a href="#/" class="w-16 h-16 mr-6 drop-shadow-md">
			<FaArrowLeft />
		</a>
		Movies
		<div class="grow" />
		<a href="#/movies/search" class="w-16 h-16 mr-6 drop-shadow-md">
			<FaSearch />
		</a>
	</h1>

	{#each rows as row}
		<h2 class="text-7xl mb-10">{row.name}</h2>
		<div class="flex flex-row justify-between mb-10">
			{#each row.titles
				// wrap around
				.concat(row.titles.slice(0, cols))
				.slice(row.index, row.index + cols) as title}
				<a
					key={title.id}
					href="#/movies/details?id={title.id}"
					class="shrink-0 w-64"
				>
					<img src="posters/{title.id}" alt={title.title} />
				</a>
			{/each}
		</div>
	{/each}
</div>
