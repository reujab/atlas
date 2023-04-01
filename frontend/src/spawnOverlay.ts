import childProcess from "child_process";
import { error, log } from "./log";
import fs from "fs";

export default function spawnOverlay(cb?: (progress: null | number[]) => void): childProcess.ChildProcess {
	const overlay = childProcess.spawn("atlas-overlay", {
		stdio: "inherit",
	});

	overlay.on("error", (err: Error) => {
		error("Overlay", err);
		cb?.(null);
	});

	overlay.once("exit", (code, sig) => {
		log("overlay exited", code, sig);
		if (code) {
			error("Overlay exit code", `${code}`);
			return;
		}
		if (code === null) return;
		fs.readFile("/tmp/progress", (err, data) => {
			if (err) {
				error("Overlay exited unexpectedly", err);
				return;
			}

			fs.unlink("/tmp/progress", (err) => {
				if (err) error("Error deleting /tmp/progress", err);
			});

			cb?.(data.toString().trim().split("\n").map(Number));
		});
	});

	return overlay;
}
