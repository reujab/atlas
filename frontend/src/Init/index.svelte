<script lang="ts">
	import Circle2 from "svelte-loading-spinners/dist/ts/Circle2.svelte";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import childProcess from "child_process";
	import { connected } from "./state";
	import { error, log } from "../log";

	const start = Date.now();
	const connectedRegex = /^(full|connected)/;

	// if network isn't connected within 3 seconds, redirect to wifi setup
	// else load the home page
	function updateConnected(): void {
		childProcess.exec(
			"nmcli -t -f CONNECTIVITY general",
			(err, stdout, stderr) => {
				if (err || stderr) {
					error("nmcli err", err || stderr);
					location.hash = "#/wifi";
					return;
				}

				log("connectivity: %O", stdout);

				$connected = connectedRegex.test(stdout);
				if ($connected) {
					location.hash = "#/home";
				} else if (Date.now() - start < 3000) {
					setTimeout(updateConnected, 500);
				} else {
					location.hash = "#/wifi";
				}
			}
		);
	}
	updateConnected();
</script>

<ErrorBanner />

<div class="h-screen px-48 flex items-center justify-center">
	<Circle2 size={256} />
</div>
