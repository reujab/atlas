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
			activeTile = Number(!activeTile);
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
