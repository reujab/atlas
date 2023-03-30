import WebTorrent from "webtorrent";
import express from "express";
import http from "http";
import parseName from "./parse";

const webtorrent = new WebTorrent({
	uploadLimit: 1000,
} as any);
const maxStreams = 10;
const streams: Stream[] = [];

let streamID = -1;
class Stream {
	id: number;

	port: number;

	magnet: string;

	torrent: null | WebTorrent.Torrent = null;

	constructor(magnet: string) {
		do {
			this.id = streamID = (streamID + 1) % maxStreams;
		} while (streams.find((s) => s.id === this.id)); // eslint-disable-line
		this.port = 1 + Number(process.env.PORT) + this.id % maxStreams;
		this.magnet = magnet;
	}
}

webtorrent.on("error", (err) => {
	console.error(err);
});

export function streamHandler(req: express.Request, res: express.Response): void {
	if (streams.length >= maxStreams) {
		res.status(500).end("Too many active streams");
		return;
	}

	const magnet = req.query.magnet as string;
	const season = req.query.s as string;
	const episode = req.query.e as string;

	if (!magnet) {
		res.status(400).end();
		return;
	}

	const existingStream = streams.find((s) => s.magnet === magnet);
	if (existingStream) {
		if (existingStream.torrent) {
			redirect(res, existingStream, season, episode);
		} else {
			const then = Date.now();
			const interval = setInterval(() => {
				if (Date.now() - then >= 60000) {
					clearInterval(interval);
					res.status(408).end();
					return;
				}

				if (existingStream.torrent) {
					redirect(res, existingStream, season, episode);
				}
			}, 500);
		}
		return;
	}

	const stream = new Stream(magnet);
	streams.push(stream);

	console.log("Connecting");
	const then = Date.now();
	req.setTimeout(3 * 60 * 1000);
	webtorrent.add(magnet, { destroyStoreOnDestroy: true }, (torrent) => {
		console.log("Connected in", ((Date.now() - then) / 1000).toFixed(2), "s");

		let torrentServer: http.Server, interval: NodeJS.Timer;

		stream.torrent = torrent;

		function cleanup(): void {
			console.log("Cleaning up");
			const index = streams.indexOf(stream);
			// eslint-disable-next-line no-negated-condition
			if (index !== -1) streams.splice(index, 1);
			else console.warn("cleanup called but stream not found");
			torrentServer?.close();
			torrent.destroy();
			clearInterval(interval);
			res.end();
		}

		torrent.on("error", (err) => {
			console.error(err);
			cleanup();
		});

		console.log(torrent.files.map((f) => f.name));
		torrentServer = torrent.createServer();
		let timeout: NodeJS.Timeout;
		let connections = 0;

		function updateTimeout(): void {
			clearTimeout(timeout);
			timeout = setTimeout(() => {
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
		torrentServer.on("error", (err) => {
			console.error(err);
			cleanup();
		});
		torrentServer.listen(stream.port, "127.0.0.1", undefined, () => {
			redirect(res, stream, season, episode);
		});
	});
}

function redirect(res: express.Response, stream: Stream, season?: string, episode?: string): void {
	if (!stream.torrent) throw new Error("torrent is null");

	const index = findFile(stream.torrent, season, episode);
	if (index === -1) {
		console.error("File not found");
		res.status(404).end();
		return;
	}
	const file = stream.torrent.files[index];
	const path = `/stream/${stream.id}/${index}/${encodeURIComponent(file.name)}`;
	res.end(path);
}

function findFile(torrent: WebTorrent.Torrent, season?: string, episode?: string): number {
	const index = season
		? torrent.files.findIndex((file) => {
			const parsed = parseName(file.name);
			return parsed.seasons.includes(Number(season)) && parsed.episode === Number(episode);
		})
		: torrent.files
			.map((file, originalIndex) => ({ file, originalIndex }))
			.sort((a, b) => b.file.length - a.file.length)
			.find((f) => /\.(?:mp4|avi|mkv)$/.test(f.file.name))?.originalIndex;
	if (index === undefined) return -1;
	return index;
}

export function proxy(req: express.Request, res: express.Response): void {
	const id = Number(req.params.id);
	const stream = streams.find((s) => s.id === id);
	if (!stream) {
		res.status(404).end("stream not found");
		return;
	}
	const path = `http://127.0.0.1:${stream.port}${req.path}`;
	req.setTimeout(3 * 60 * 1000);
	http.get(path, { headers: req.headers }, (streamRes) => {
		for (const header of Object.keys(streamRes.headers)) {
			if (header.includes("dlna")) continue;
			res.header(header, streamRes.headers[header]);
		}
		streamRes.pipe(res, { end: true });

		req.on("close", () => {
			streamRes.destroy();
		});
	});
}
