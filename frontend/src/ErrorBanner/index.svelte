<script lang="ts">
	import FaCircleExclamation from "svelte-icons/fa/FaExclamationCircle.svelte";
	import { error as errorStore, ErrorMessage } from "./store";

	let active = false;
	let error: null | ErrorMessage;
	let timeout: NodeJS.Timer;

	errorStore.subscribe((err) => {
		if (err) {
			active = true;
			error = err;
			clearTimeout(timeout);
			timeout = setTimeout(() => {
				errorStore.update(() => null);
			}, 5000);
		} else {
			active = false;
		}
	});
</script>

<div class="error flex absolute left-0 right-0 justify-center" class:active>
	<div class="flex rounded-full bg-red-400 text-white items-center p-4 gap-4">
		<div class="h-16 w-16">
			<FaCircleExclamation />
		</div>
		<div class="flex flex-col">
			<div class="text-5xl">{error?.msg}</div>
			{#if error?.err}
				<div class="text-3xl">{`${error?.err}`}</div>
			{/if}
		</div>
	</div>
</div>

<style>
	.error {
		top: -8rem;
		transition: top 500ms;
	}

	.error.active {
		top: 1rem;
	}
</style>
