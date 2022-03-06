<script>
	export let icon;
	export let title;
	export let iconClass;
</script>

<div
	class="w-64 h-64 bg-white shrink-0 items-center flex flex-col p-2 rounded-xl drop-shadow-xl"
>
	<div class="p-2 w-40 h-40 flex justify-center items-center {iconClass}">
		<svelte:component this={icon} />
	</div>
	<div class="grow" />
	<div class="text-5xl">
		{title}
	</div>
</div>
