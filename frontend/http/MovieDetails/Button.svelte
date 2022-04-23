<script>
	export let text, icon, active;
</script>

<div
	class="button p-16 h-16 flex items-center cursor-pointer text-5xl font-light border rounded-full drop-shadow-md bg-white"
	class:active
>
	<div class="w-12 h-12 mr-8">
		<svelte:component this={icon} />
	</div>
	{text}
</div>

<style>
	.button.active,
	.button:hover {
		border-color: black;
	}
</style>
