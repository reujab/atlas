<script>
	import FaArrowLeft from "svelte-icons/fa/FaArrowLeft.svelte";
	import FaSearch from "svelte-icons/fa/FaSearch.svelte";
</script>

<div class="h-screen px-48 bg-white">
	<h1 class="text-8xl font-light pt-10 flex items-center">
		<a href="#/" class="w-16 h-16 mr-6">
			<FaArrowLeft />
		</a>
		Movies
		<div class="grow" />
		<a href="#/movies/search" class="w-16 h-16 mr-6">
			<FaSearch />
		</a>
	</h1>
</div>
