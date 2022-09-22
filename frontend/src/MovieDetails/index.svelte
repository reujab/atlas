<script lang="ts">
	import Button from "./Button.svelte";
	import FaDownload from "svelte-icons/fa/FaDownload.svelte";
	import FaPlay from "svelte-icons/fa/FaPlay.svelte";
	import FaYoutube from "svelte-icons/fa/FaYoutube.svelte";
	import Header from "../Header/index.svelte";
	import Rating from "./Rating.svelte";
	import { cache, genres } from "../db";
	import { log } from "../log";
	import { onDestroy } from "svelte";
	import { params } from "svelte-hash-router";
	import { subscribe, unsubscribe } from "../gamepad";

	const title = cache[$params.id];
	log("%O", title);
	const playHref = `#/results/${escape(title.title)
		.replace(/\./g, "%2E")
		.replace(/\+/g, "%2B")}`;

	let activeButton = 0;

	const releaseDate = title.released?.toLocaleDateString(undefined, {
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
					case 2:
						location.href = `#/trailer/${title.id}`;
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
				let lastButton = title.trailer ? 2 : 1;
				if (activeButton < lastButton) {
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

	<div class="flex grow items-center">
		<div class="flex gap-4 my-4">
			<div class="shrink-0 flex flex-col gap-4">
				<img
					src="file:///{process.env.POSTERS_PATH}/movie/{title.id}"
					alt="Poster"
					class="rounded-md white-shadow "
				/>

				<span class="text-3xl text-center">{releaseDate}</span>
			</div>

			<div>
				<h3 class="text-4xl mb-8">
					{#if title.rating}
						<Rating rating={title.rating} />
					{/if}
					<span class:ml-2={title.rating}>
						{title.genres
							?.map((genre) => genres[genre])
							.join(" • ")}
					</span>
				</h3>

				<h3 class="text-3xl">
					{title.overview}
				</h3>
			</div>
		</div>
	</div>

	<div class="flex justify-around mb-16">
		<a href={playHref}>
			<Button icon={FaPlay} text="Play" active={activeButton === 0} />
		</a>
		<Button icon={FaDownload} text="Download" active={activeButton === 1} />
		{#if title.trailer}
			<a href="#/trailer/{title.id}">
				<Button
					icon={FaYoutube}
					text="Watch trailer"
					active={activeButton === 2}
				/>
			</a>
		{/if}
	</div>
</div>
