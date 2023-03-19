<script lang="ts">
	export let title: Title;

	import { Title, progress } from "../db";
</script>

<div class="relative rounded-lg white-shadow overflow-hidden">
	{@html title.posterImg?.outerHTML}
	{#if title.type === "movie" && $progress[title.type][title.id]}
		<div class="absolute bottom-0 left-0 right-0 h-1">
			<div
				style="width: {$progress[title.type][title.id] * 100}%"
				class="bg-red-500 h-full"
			/>
		</div>
	{/if}
</div>
