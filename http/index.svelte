<script>
	import HomeTile from "./HomeTile";
	import FaFilm from "svelte-icons/fa/FaFilm.svelte";
	import FaTv from "svelte-icons/fa/FaTv.svelte";
</script>

<div id="main" class="h-screen px-48">
	<div
		class="overflow-x-scroll flex flex-col gap-48 justify-center content-start flex-wrap h-full"
	>
		<HomeTile title="Movies" icon={FaFilm} iconClass="text-indigo-700" />
		<HomeTile title="TV Shows" icon={FaTv} iconClass="text-lime-700" />
		<HomeTile title="Movie" icon={FaFilm} iconClass="text-indigo-700" />
		<HomeTile title="TV Show" icon={FaTv} iconClass="text-lime-700" />
		<HomeTile title="Movi" icon={FaFilm} iconClass="text-indigo-700" />
		<HomeTile title="TV Sho" icon={FaTv} iconClass="text-lime-700" />
		<HomeTile title="Mov" icon={FaFilm} iconClass="text-indigo-700" />
		<HomeTile title="TV Sh" icon={FaTv} iconClass="text-lime-700" />
	</div>
</div>

<style>
	:global(body) {
		background: black;
	}

	#main {
		background-image: url(./textures/light/7.jpg);
		background-size: cover;
		font-family: Cantarell;
		border-radius: 25px;
	}
</style>
