<script lang="ts">
	export let title: string,
		back = false,
		search: null | string = null;

	import FaArrowLeft from "svelte-icons/fa/FaArrowLeft.svelte";
	import FaSearch from "svelte-icons/fa/FaSearch.svelte";
	import GamepadButton from "../GamepadButton.svelte";
</script>

<h1 class="text-8xl font-light pt-10 flex items-center mb-2">
	{#if back}
		<div class="mr-6 cursor-pointer">
			<div
				class="w-16 h-16 drop-shadow-md p-1 content-box"
				on:click={history.back.bind(history)}
			>
				<GamepadButton button="B" />
				<FaArrowLeft />
			</div>
		</div>
	{/if}
	{title}
	<div class="grow" />
	{#if search}
		<a
			href="#{search}"
			class="w-16 h-16 mr-6 drop-shadow-md icon p-1 content-box"
		>
			<GamepadButton button="Y" />
			<FaSearch />
		</a>
	{/if}
</h1>
