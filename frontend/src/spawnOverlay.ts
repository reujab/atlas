import childProcess from "child_process";
import { error } from "./log";
import fs from "fs";

export default function spawnOverlay(torrent: boolean, cb: (progress: null | number) => void): childProcess.ChildProcess {
	const overlay = childProcess.spawn("atlas-overlay", torrent ? ["--torrent"] : null, {
		stdio: "inherit",
	});

	overlay.on("error", (err: Error) => {
		error("Overlay", err);
		cb(null);
	});

	overlay.once("exit", (code) => {
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

			console.log(data.toString());
			cb(Number(data));
		});
	});

	return overlay;
}
