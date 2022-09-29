<script lang="ts">
	export let text: string, icon: any, active: boolean;
</script>

<div
	class="button p-16 h-16 flex items-center cursor-pointer text-5xl font-light border rounded-full drop-shadow-md bg-[#eee] text-black"
	class:active
>
	{#if icon}
		<div class="w-12 h-12 mr-8">
			<svelte:component this={icon} />
		</div>
	{/if}
	{text}
</div>

<style>
	.button {
		transition: transform 500ms;
	}

	.button.active {
		transform: scale(1.1);
	}
</style>
