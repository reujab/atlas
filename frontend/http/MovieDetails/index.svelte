<script>
	import Button from "./Button";
	import FaDownload from "svelte-icons/fa/FaDownload.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import FaPlus from "svelte-icons/fa/FaPlus.svelte";
	import Header from "../Header";
	import { cache, genres } from "../db";
	import { params } from "svelte-hash-router";

	const title = cache[$params.id];
	console.log(title);

	const releaseDate = new Date(title.released).toLocaleDateString(undefined, {
		day: "numeric",
		month: "long",
		year: "numeric",
	});
</script>

<div class="h-screen px-48 bg-white flex flex-col">
	<Header title={title.title} back />

	<div class="min-h-[450px]">
		<img src="posters/{title.id}" alt="Poster" class="float-left mr-4" />

		<h3 class="text-5xl mb-8">
			{title.genres.map((genre) => genres[genre]).join(" • ")}
		</h3>

		<h3 class="text-5xl">{title.overview}</h3>

		<h3 class="text-3xl mt-8">{releaseDate}</h3>
	</div>

	<div class="grow" />

	<div class="flex justify-around mb-16">
		<!-- svelte-ignore missing-declaration -->
		<a href="#/search/{escape(title.title)}">
			<Button icon={FaPlay} text="Play" />
		</a>
		<Button icon={FaDownload} text="Download" />
		<Button icon={FaPlus} text="Add to watchlist" />
	</div>
</div>
