<script>
	import { invoke } from "@tauri-apps/api";
	import { GamepadListener } from "gamepad.js";

	let src;

	function getNewImage() {
		invoke("get_image").then((img) => {
			src = img;
		});
	}

	getNewImage();

	const listener = new GamepadListener();
	listener.start();
	listener.on("gamepad:button", (e) => {
		console.log(e);
		if (e.detail.pressed) {
			getNewImage();
		}
	});
</script>

<div class="h-screen flex items-center content-center" on:click={getNewImage}>
	<img {src} alt="" class="max-h-screen" />
</div>
