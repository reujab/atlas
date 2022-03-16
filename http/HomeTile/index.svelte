<script>
	export let title, icon, iconClass, active;
</script>

<div
	class="tile w-64 h-64 bg-white shrink-0 items-center flex flex-col p-2 rounded-xl drop-shadow-xl {active
		? 'active'
		: ''}"
>
	<div class="p-2 w-40 h-40 flex justify-center items-center {iconClass}">
		<svelte:component this={icon} />
	</div>
	<div class="grow" />
	<div class="text-5xl">
		{title}
	</div>
</div>

<style>
	.tile {
		transition: transform 100ms ease-in-out;
	}

	.tile.active,
	.tile:hover {
		transform: scale(1.1);
	}
</style>
