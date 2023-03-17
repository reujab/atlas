import WebTorrent from "webtorrent";
import express from "express";
import http from "http";
import parseName from "./parse";

const webtorrent = new WebTorrent({
	// uploadLimit: 0,
});
const maxStreams = 10;

const streams: Map<string, null | string> = new Map();
let streamID = -1;

export default function stream(req: express.Request, res: express.Response): void {
	if (streams.size >= maxStreams) {
		res.status(500).end("Too many active streams");
		return;
	}

	const magnet = req.query.magnet as string;
	const season = req.query.s;
	const episode = req.query.e;

	if (!magnet) {
		res.status(400).end();
		return;
	}

	if (streams.get(magnet) !== undefined) {
		if (streams.get(magnet) === null) {
			const then = Date.now();
			const interval = setInterval(() => {
				if (Date.now() - then >= 10000) {
					clearInterval(interval);
					res.status(500).end("Stream never initialized");
					return;
				}

				if (streams.get(magnet)) {
					res.end(streams.get(magnet));
				}
			}, 100);
		} else {
			res.end(streams.get(magnet));
		}

		return;
	}

	streams.set(magnet, null);

	console.log(season, episode);
	console.log("Connecting");

	webtorrent.add(magnet, { destroyStoreOnDestroy: true }, (torrent) => {
		console.log("Connected");

		let torrentServer: http.Server, interval: NodeJS.Timer;

		function cleanup(): void {
			torrentServer?.close();
			torrent.destroy();
			clearInterval(interval);
			res.end();
			streams.delete(magnet);
		}

		torrent.on("error", (err) => {
			console.error(err);
			cleanup();
		});

		console.log(torrent.files.map((f) => f.name));
		const index = season
			? torrent.files.findIndex((file) => {
				const parsed = parseName(file.name);
				return parsed.seasons.includes(Number(season)) && parsed.episode === Number(episode);
			})
			: torrent.files
				.map((file, originalIndex) => ({ file, originalIndex }))
				.sort((a, b) => b.file.length - a.file.length)
				.find((f) => /\.(?:mp4|avi|mkv)$/.test(f.file.name))?.originalIndex;
		if (index === undefined || index === -1) {
			console.error("File not found");
			res.status(404);
			cleanup();
			return;
		}

		const file = torrent.files[index];
		console.log(`Selecting "${file.name}"`);
		file.select();

		torrentServer = torrent.createServer();
		let timeout: NodeJS.Timeout;
		let connections = 0;

		function updateTimeout(): void {
			clearTimeout(timeout);
			timeout = setTimeout(() => {
				console.log("Timeout");
				cleanup();
			}, 10000);
		}

		updateTimeout();
		torrentServer.on("connection", (socket) => {
			console.log(++connections);
			clearTimeout(timeout);

			socket.on("close", () => {
				console.log(--connections);
				if (!connections) {
					updateTimeout();
				}
			});
		});
		const port = 8001 + ++streamID % 999;
		torrentServer.listen(port, "0.0.0.0", undefined, () => {
			streams.set(magnet, `:${port}/${index}/${encodeURIComponent(file.name)}`);
			res.end(streams.get(magnet));
		});
	});
}
