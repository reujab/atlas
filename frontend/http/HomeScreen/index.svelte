<script>
	import HomeTile from "./HomeTile";
	import FaFilm from "svelte-icons/fa/FaFilm.svelte";
	import FaTv from "svelte-icons/fa/FaTv.svelte";
	import listener from "../gamepad";
	import { onDestroy } from "svelte";

	// set background based on time of day
	const hour = new Date().getHours();
	const timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
	const index = Math.floor(Math.random() * (timeOfDay === "day" ? 4 : 23));
	const img = `url(./backgrounds/${timeOfDay}/${index}.webp)`;

	// home tiles
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
	];
	let activeTile = 0;

	function gamepadHandler(e) {
		if (e.detail.pressed) {
			console.log(e.detail.button);
			switch (e.detail.button) {
				case 0: // A button
					location.hash = `#${tiles[activeTile].path}`;
					break;
				case 12: // pad up
					if (activeTile % 2 == 1) {
						activeTile -= 1;
					}
					break;
				case 13: // pad down
					if (activeTile % 2 == 0) {
						activeTile += 1;
					}
					break;
				case 14: // pad left
					if (activeTile >= 2) {
						activeTile -= 2;
					}
					break;
				case 15: // pad right
					if (activeTile + 2 < tiles.length) {
						activeTile += 2;
					}
					break;
			}
			activeTile = Math.max(0, Math.min(tiles.length - 1, activeTile));
		}
	}

	listener.on("gamepad:button", gamepadHandler);

	// disable controller when the mouse is moved
	function mouseMove() {
		activeTile = -1;
		removeEventListener("mousemove", mouseMove);
	}
	addEventListener("mousemove", mouseMove);

	onDestroy(() => {
		listener.off("gamepad:button", gamepadHandler);
		removeEventListener("mousemove", mouseMove);
	});
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
