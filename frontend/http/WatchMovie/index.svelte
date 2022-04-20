<script>
	import { invoke } from "@tauri-apps/api";
	import { params } from "svelte-hash-router";
	import { cache } from "../db";

	let title = cache[$params.id];
</script>

<div>TODO</div>
