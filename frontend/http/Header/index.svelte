<script>
	export let title, back, search;

	import FaArrowLeft from "svelte-icons/fa/FaArrowLeft.svelte";
	import FaSearch from "svelte-icons/fa/FaSearch.svelte";
</script>

<h1 class="text-8xl font-light pt-10 flex items-center mb-10">
	{#if back}
		<a href="#{back}" class="w-16 h-16 mr-6 drop-shadow-md">
			<FaArrowLeft />
		</a>
	{/if}
	{title}
	<div class="grow" />
	{#if search}
		<a href="#{search}" class="w-16 h-16 mr-6 drop-shadow-md">
			<FaSearch />
		</a>
	{/if}
</h1>
