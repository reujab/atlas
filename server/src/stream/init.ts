import { Request, Response } from "express";
import { Torrent } from "webtorrent";
import parseName from "../magnet/parse_name";
import sql from "../sql";
import Stream, { streams } from "./Stream";

const maxStreams = 2;

/**
 * Starts downloading the magnet and sends information about the stream, including UUID, stream URL,
 * and subtitles.
 * */
export default async function initStream(req: Request, res: Response): Promise<void> {
	if (streams.length >= maxStreams) {
		res.status(503).end();
		return;
	}

	const uuid = req.params.uuid;
	const season = req.query.s as string;
	const episode = req.query.e as string;

	const existingStream = streams.find((s) => s.uuid === uuid);
	if (existingStream) {
		serveInfo(res, existingStream, season, episode);
		return;
	}

	// FIXME: possible race condition resulting in duplicate streams?
	const row = await sql`
		SELECT magnet FROM magnets
		WHERE uuid = ${uuid}
		LIMIT 1
	`;
	if (!row.length) {
		console.warn("Could not find uuid:", uuid);
		res.status(404).end();
		return;
	}
	const magnet = row[0].magnet;

	req.setTimeout(3 * 60 * 1000);
	const stream = new Stream(uuid, magnet);
	streams.push(stream);
	stream.init();
	serveInfo(res, stream, season, episode);
}

function serveInfo(res: Response, stream: Stream, season?: string, episode?: string): void {
	if (!stream.started) {
		stream.once("start", () => {
			serveInfo(res, stream, season, episode);
		});
		return;
	}

	const index = findFile(stream.torrent!, season, episode);
	if (index === -1) {
		console.error("Could not find file", season, episode);
		for (const file of stream.torrent!.files) {
			console.log(file.name, parseName(file.name));
		}
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
