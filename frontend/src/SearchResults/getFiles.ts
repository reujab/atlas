import child_process from "child_process";
import { log } from "../log";
import { parseName } from "./search";

export interface File {
	name: string,
	size: string,
	seasons: null | number[],
	episode: null | number,
}

export default function getFiles(magnet: string): Promise<File[]> {
	return new Promise((resolve, reject) => {
		const webtorrent = child_process.spawn("webtorrent", [magnet, "-s"]);
		let stdout = "";

		webtorrent.on("error", (err) => {
			reject(err);
		});

		webtorrent.stdout.on("data", (chunk) => {
			stdout += chunk;
		});

		webtorrent.stderr.on("data", (chunk) => {
			process.stderr.write(chunk);
		});

		webtorrent.on("exit", (code) => {
			if (code !== 0) {
				reject(`webtorrent exit code: ${code}`);
				return;
			}

			log("stdout: %O", stdout);
			const matches = stdout.matchAll(
				/^\d+ *(.+\.(?:mkv|mp4|avi)) \(([\d.,]+ .+)\)$/gm
			);

			resolve([...matches].map((match) => (
				Object.assign({
					name: match[1],
					size: match[2],
				}, parseName(match[1]))
			)).sort(
				(a, b) => {
					if (a.seasons && b.seasons && a.seasons[0] !== b.seasons[0])
						if (a.seasons[0] < b.seasons[0])
							return -1;
						else
							return 1;
					if (!a.episode && !b.episode)
						return a.name.localeCompare(b.name);
					if (!a.episode && b.episode)
						return 1;
					if (a.episode && !b.episode)
						return -1;
					return a.episode - b.episode;
				}
			));
		});
	});
}
