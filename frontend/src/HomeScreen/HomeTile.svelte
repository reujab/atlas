<script lang="ts">
	import { Tile } from "./index.svelte";
	export let tile: Tile, active: boolean;
</script>

<a
	href="#{tile.path}"
	class="tile w-64 h-64 bg-white shrink-0 items-center flex flex-col p-2 rounded-xl drop-shadow-xl border border-1 border-slate-300 font-light"
	class:active
>
	<div class="p-2 w-40 h-40 flex justify-center items-center">
		<img src={tile.icon} alt={tile.title} />
	</div>
	<div class="grow" />
	<div class="text-5xl">
		{tile.title}
	</div>
</a>

<style>
	.tile {
		transition: transform 500ms;
	}

	.tile.active {
		transform: scale(1.15);
	}
</style>
