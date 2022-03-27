<script>
	import { invoke } from "@tauri-apps/api";
	import { params } from "svelte-hash-router";
	import { cache } from "../db";

	let title = cache[$params.id];
	let src;

	invoke("get_video_url", { slug: title.slug }).then((url) => {
		console.log(url);
		src = url;
	});
</script>

{#if src}
	<video {src} autoplay />
{/if}
