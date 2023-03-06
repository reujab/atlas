<script lang="ts">
	export let title: Title;

	import { Title } from "../db";
</script>

<div class="relative rounded-lg white-shadow overflow-hidden">
	{@html title.poster?.outerHTML}
	{#if title.progress}
		<div class="absolute bottom-0 left-0 right-0 h-1">
			<div
				style="width: {title.progress * 100}%"
				class="bg-red-500 h-full"
			/>
		</div>
	{/if}
</div>
