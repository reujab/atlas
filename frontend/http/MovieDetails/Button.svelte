<script>
	export let text, icon, onClick;
</script>

<div
	class="p-16 h-16 flex items-center cursor-pointer text-5xl font-light border rounded-full drop-shadow-md bg-white"
	on:click={onClick}
>
	<div class="w-12 h-12 mr-8">
		<svelte:component this={icon} />
	</div>
	{text}
</div>
