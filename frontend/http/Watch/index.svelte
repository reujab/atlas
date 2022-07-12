<script>
	import { query } from "svelte-hash-router";
	import { invoke } from "@tauri-apps/api";
	import { Circle2 } from "svelte-loading-spinners";

	let src = $query.src;
	let loading = true;

	onclick = () => {
		console.log("clicking");
		document.querySelector("video").play();
	};

	function click() {
		console.log("canplay");
		invoke("click");
	}
</script>

<!-- svelte-ignore a11y-media-has-caption -->
<video
	autoplay
	{src}
	on:canplay={click}
	on:waiting={() => (console.log("waiting"), (loading = true))}
	on:play={() => (console.log("play"), (loading = false))}
	on:playing={() => (console.log("playing"), (loading = false))}
	on:stalled={() => (console.log("stalled"), (loading = true))}
	on:suspend={() => (console.log("suspend"), (loading = true))}
	class="h-full max-h-screen w-full m-auto"
/>

{#if loading}
	<div class="flex justify-center items-center absolute inset-0">
		<Circle2 size={256} />
	</div>
{/if}
