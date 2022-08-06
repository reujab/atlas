<script lang="ts">
	export let error: string;

	import FaCircleExclamation from "svelte-icons/fa/FaExclamationCircle.svelte";
</script>

{#if error}
	<dialog class="top-0 bottom-0 drop-shadow-lg" open={Boolean(error)}>
		<h1 class="text-6xl text-center flex border-bottom border-black mb-4">
			<div class="w-16 h-16 text-red-500 inline-block">
				<FaCircleExclamation />
			</div>
			Error
		</h1>
		<div>{error}</div>
	</dialog>
{/if}
