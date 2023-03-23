<script lang="ts">
	import Circle2 from "svelte-loading-spinners/dist/ts/Circle2.svelte";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import childProcess from "child_process";
	import { connected } from "./state";
	import { error } from "../log";

	const network = /ethernet|wireless/;

	childProcess.exec(
		"nmcli -t -f TYPE con show --active",
		(err, stdout, stderr) => {
			if (err || stderr) {
				error("nmcli err", err || stderr);
				location.hash = "#/wifi";
				return;
			}

			$connected =
				stdout
					.trim()
					.split("\n")
					.findIndex((l) => network.test(l)) !== -1;

			if ($connected) {
				location.hash = "#/home";
			} else {
				location.hash = "#/wifi";
			}
		}
	);
</script>

<ErrorBanner />

<div class="h-screen px-48 flex items-center content-center">
	<Circle2 size={256} />
</div>
