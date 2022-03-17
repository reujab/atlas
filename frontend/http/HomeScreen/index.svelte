<script>
	import HomeTile from "./HomeTile";
	import FaFilm from "svelte-icons/fa/FaFilm.svelte";
	import FaTv from "svelte-icons/fa/FaTv.svelte";
	import FaPhotoVideo from "svelte-icons/fa/FaPhotoVideo.svelte";
	import { GamepadListener } from "gamepad.js";

	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const index = Math.floor(Math.random() * (timeOfDay === "day" ? 4 : 23));
	const img = `url(./backgrounds/${timeOfDay}/${index}.webp)`;

	const tiles = [
		{
			title: "Movies",
			path: "/movies",
			icon: FaFilm,
			iconClass: "text-indigo-700",
		},
		{
			title: "TV Shows",
			path: "/shows",
			icon: FaTv,
			iconClass: "text-lime-700",
		},
		{
			title: "Pictures",
			path: "/pictures",
			icon: FaPhotoVideo,
			iconClass: "text-amber-700",
		},
	];
	let activeTile = 0;

	const listener = new GamepadListener();
	listener.start();
	listener.on("gamepad:button", (e) => {
		console.log(e);
		if (e.detail.pressed) {
			switch (e.detail.button) {
				case 0: // A button
					location.hash = `#${tiles[activeTile].path}`;
					break;
				case 12: // pad left
					if (activeTile % 2 == 1) {
						activeTile -= 1;
					}
					break;
				case 13: // pad right
					if (activeTile % 2 == 0) {
						activeTile += 1;
					}
					break;
				case 14: // pad up
					if (activeTile >= 2) {
						activeTile -= 2;
					}
					break;
				case 15: // pad down
					activeTile += 2;
					break;
			}
			activeTile = Math.max(0, Math.min(tiles.length - 1, activeTile));
		}
	});

	function mouseMove() {
		activeTile = -1;
		removeEventListener("mousemove", mouseMove);
	}
	addEventListener("mousemove", mouseMove);
</script>

<div
	class="h-screen px-48 rounded-[25px] bg-cover flex items-center"
	style="background-image: {img}"
>
	<div class="flex flex-col gap-48 flex-wrap h-[44rem]">
		{#each tiles as tile, i}
			<HomeTile {tile} active={activeTile === i} />
		{/each}
	</div>
</div>
