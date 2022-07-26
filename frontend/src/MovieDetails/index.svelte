<script lang="ts">
	import Button from "./Button";
	import FaDownload from "svelte-icons/fa/FaDownload.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import FaPlus from "svelte-icons/fa/FaPlus.svelte";
	import Header from "../Header";
	import { cache, genres } from "../db";
	import { log } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const title = cache[$params.id];
	log("%O", title);
	const playHref = `#/search/${escape(title.title)
		.replace(/\./g, "%2E")
		.replace(/\+/g, "%2B")}`;

	let activeButton = 0;

	const releaseDate = new Date(title.released).toLocaleDateString(undefined, {
		day: "numeric",
		month: "long",
		year: "numeric",
	});

	function gamepadHandler(button: string) {
		switch (button) {
			case "A":
				switch (activeButton) {
					case 0:
						location.href = playHref;
						break;
				}
				break;
			case "B":
				history.back();
				break;
			case "left":
				if (activeButton > 0) {
					activeButton--;
				}
				break;
			case "right":
				if (activeButton < 2) {
					activeButton++;
				}
				break;
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen px-48 bg-white flex flex-col">
	<Header title={title.title} back />

	<div class="min-h-[450px] mt-4">
		<img
			src="posters/movie/{title.id}"
			alt="Poster"
			class="float-left mr-4"
		/>

		<h3 class="text-3xl mb-8">
			{title.genres.map((genre) => genres[genre]).join(" • ")}
		</h3>

		<h3 class="text-4xl">
			{title.overview}
		</h3>

		<h3 class="text-3xl mt-8">{releaseDate}</h3>
	</div>

	<div class="grow" />

	<div class="flex justify-around mb-16">
		<a href={playHref}>
			<Button icon={FaPlay} text="Play" active={activeButton === 0} />
		</a>
		<Button icon={FaDownload} text="Download" active={activeButton === 1} />
		<Button
			icon={FaPlus}
			text="Add to watchlist"
			active={activeButton === 2}
		/>
	</div>
</div>
