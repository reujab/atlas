import child_process from "child_process";
import { log } from "./log";

export default function spawnOverlay(cb?: (code?: number) => void) {
	// once mpv has started, spawn the overlay
	let started = false;
	async function checkPosition() {
		const child = child_process.spawn("playerctl", ["position"]);
		child.stdout.on("data", (data) => {
			log(data.toString());
			const position = Number(data.toString().trim());
			if (position > 0.1) {
				started = true;

				setTimeout(() => {
					const overlay = child_process.spawn("atlas-overlay", {
						detached: true,
						stdio: "inherit",
					});

					if (cb) {
						overlay.on("exit", cb);
					}
				}, 2000);
			}
		});
		child.on("exit", () => {
			if (!started) {
				setTimeout(checkPosition, 100);
			}
		});
	}
	checkPosition();
}
