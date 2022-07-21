<script>
	export let tile, active;
</script>

<a
	href="#{tile.path}"
	class="tile w-64 h-64 bg-white shrink-0 items-center flex flex-col p-2 rounded-xl drop-shadow-xl {active
		? 'active'
		: ''}"
>
	<div
		class="p-2 w-40 h-40 flex justify-center items-center {tile.iconClass}"
	>
		<svelte:component this={tile.icon} />
	</div>
	<div class="grow" />
	<div class="text-5xl">
		{tile.title}
	</div>
</a>

<style>
	.tile.active,
	.tile:hover {
		border: 0.5rem solid black;
		padding: 0;
	}
</style>
