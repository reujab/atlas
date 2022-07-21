<script>
	export let title, back, search;

	import FaArrowLeft from "svelte-icons/fa/FaArrowLeft.svelte";
	import FaSearch from "svelte-icons/fa/FaSearch.svelte";
</script>

<h1 class="text-8xl font-light pt-10 flex items-center mb-2">
	{#if back}
		<div class="icon mr-6 cursor-pointer">
			<div
				class="w-16 h-16 drop-shadow-md p-1 content-box"
				on:click={history.back.bind(history)}
			>
				<FaArrowLeft />
			</div>
		</div>
	{/if}
	{title}
	<div class="grow" />
	{#if search}
		<a
			href="#{search}"
			class="w-16 h-16 mr-6 drop-shadow-md icon p-1 content-box"
		>
			<FaSearch />
		</a>
	{/if}
</h1>

<style>
	.icon {
		border: 4px solid transparent;
		border-radius: 0.5rem;
	}

	.icon:hover {
		border-color: black;
	}
</style>
