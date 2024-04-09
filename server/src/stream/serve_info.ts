import { Response } from "express";
import { Torrent } from "webtorrent";
import parseName from "../magnet/parse_name";
import Stream from "./Stream";

export default function serveInfo(res: Response, stream: Stream, season?: string, episode?: string): void {
	const index = findFile(stream.torrent!, season, episode);
	if (index === -1) {
		console.error("Could not find file");
		res.status(404).end();
		return;
	}
	const base = `/stream/${stream.uuid}`;
	const file = stream.torrent!.files[index];
	const filePath = `${base}/${index}/${encodeURIComponent(file.name)}`;
	const subs = stream.torrent!.files.find((s) => s.name === file.name.replace(/...$/, "srt"));
	const subsPath = subs
		? `${base}/${stream.torrent!.files.indexOf(subs)}/${encodeURIComponent(subs.name)}`
		: null;
	res.json({
		video: filePath,
		subs: subsPath,
	});
}

function findFile(torrent: Torrent, season?: string, episode?: string): number {
	// Sort the files by length, preserving the original index.
	// This prevents "sample" files from playing instead of the actual video.
	const files = torrent.files
		.map((file, originalIndex) => ({ file, originalIndex }))
		.sort((a, b) => b.file.length - a.file.length);
	const file = season
		? files.find((f) => {
			const parsed = parseName(f.file.name);
			return parsed.seasons.includes(Number(season)) && parsed.episode === Number(episode);
		})
		: files.find((f) => /\.(?:mp4|avi|mkv)$/.test(f.file.name));
	const index = file?.originalIndex ?? -1;
	return index;
}
