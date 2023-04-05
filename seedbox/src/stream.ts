import WebTorrent from "webtorrent";
import express from "express";
import http from "http";
import parseName from "./parse";
import EventEmitter from "events";

const webtorrent = new WebTorrent({
	uploadLimit: 0.25 * 1024 * 1024,
} as any);
const maxStreams = 10;
const streams: Stream[] = [];

let streamID = -1;
class Stream extends EventEmitter {
	id: number;

	port: number;

	magnet: string;

	torrent: null | WebTorrent.Torrent = null;

	clients = 0;

	private server: null | http.Server = null;

	private interval: null | NodeJS.Timer = null;

	private logInterval: null | NodeJS.Timer = null;

	constructor(magnet: string) {
		super();
		do {
			this.id = streamID = (streamID + 1) % maxStreams;
		} while (streams.find((s) => s.id === this.id)); // eslint-disable-line
		this.port = 1 + Number(process.env.PORT) + this.id;
		this.magnet = magnet;
	}

	init(): void {
		console.log("Connecting");
		const then = Date.now();
		this.clients++;
		webtorrent.add(this.magnet, { destroyStoreOnDestroy: true }, (torrent) => {
			console.log("Connected in", ((Date.now() - then) / 1000).toFixed(2), "s");

			this.torrent = torrent;

			this.logInterval = setInterval(() => {
				console.log("Downloaded", Math.floor(torrent.downloaded / torrent.length * 100), "%");
				if (torrent.downloaded === torrent.length && this.logInterval) clearInterval(this.logInterval);
			}, 60000);


			torrent.on("error", (err) => {
				console.error(err);
			});

			console.log(torrent.files.map((f) => f.name));
			this.server = torrent.createServer();
			let timeout: NodeJS.Timeout;
			let connections = 0;

			const updateTimeout = (): void => {
				clearTimeout(timeout);
				timeout = setTimeout(() => {
					this.destroy();
				}, 60 * 60 * 1000);
			};

			updateTimeout();
			this.server.on("connection", (socket) => {
				console.log("Connections:", ++connections);
				clearTimeout(timeout);

				socket.on("close", () => {
					console.log("Connections:", --connections);
					if (!connections) {
						updateTimeout();
					}
				});
			});
			this.server.on("error", (err) => {
				console.error(err);
			});
			this.server.listen(this.port, "127.0.0.1", undefined, () => {
				this.emit("start");
			});
		});
	}

	delete(): void {
		if (!--this.clients) this.destroy();
	}

	destroy(): void {
		console.log("Destroying stream", this.id);
		const index = streams.indexOf(this);
		// eslint-disable-next-line no-negated-condition
		if (index !== -1) streams.splice(index, 1);
		else console.warn("destroy called but stream not found");
		console.log(streams);
		this.server?.close();
		this.torrent?.destroy();
		if (this.interval) clearInterval(this.interval);
		if (this.logInterval) clearInterval(this.logInterval);
		this.emit("end");
	}
}

webtorrent.on("error", (err) => {
	console.error(err);
});

setInterval(() => {
	if (streams.length)
		console.log(
			"DL:",
			Math.round(webtorrent.downloadSpeed / 1024),
			"KiB/s",
			"UP:", Math.round(webtorrent.uploadSpeed / 1024), "KiB/s"
		);
}, 10000);

export function init(req: express.Request, res: express.Response): void {
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
		existingStream.clients++;
		if (existingStream.torrent) {
			serveInfo(res, existingStream, season, episode);
		} else {
			const then = Date.now();
			const interval = setInterval(() => {
				if (Date.now() - then >= 60000) {
					clearInterval(interval);
					res.status(408).end();
					return;
				}

				if (existingStream.torrent) {
					clearInterval(interval);
					serveInfo(res, existingStream, season, episode);
				}
			}, 500);
		}
		return;
	}

	req.setTimeout(3 * 60 * 1000);
	const stream = new Stream(magnet);
	streams.push(stream);
	stream.on("start", () => {
		serveInfo(res, stream, season, episode);
	});
	stream.init();
}

function serveInfo(res: express.Response, stream: Stream, season?: string, episode?: string): void {
	if (!stream.torrent) throw new Error("torrent is null");

	const index = findFile(stream.torrent, season, episode);
	if (index === -1) {
		res.status(404).end();
		return;
	}
	const base = `/stream/${btoa(stream.magnet)}`;
	const file = stream.torrent.files[index];
	const filePath = `${base}/${index}/${encodeURIComponent(file.name)}`;
	const subs = stream.torrent.files.find((s) => s.name === file.name.replace(/...$/, "srt"));
	const subsPath = subs ? `${base}/${stream.torrent.files.indexOf(subs)}/${encodeURIComponent(subs.name)}` : null;
	res.json({
		video: filePath,
		subs: subsPath,
		delete: base,
	});
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
	req.setTimeout(3 * 60 * 1000);
	const magnet = atob(req.params.magnetBase64);
	let stream = streams.find((s) => s.magnet === magnet);

	function proxyFile(): void {
		if (!stream) throw new Error();
		const path = `http://127.0.0.1:${stream.port}${req.path}`;
		http.get(path, { headers: req.headers }, (streamRes) => {
			for (const header of Object.keys(streamRes.headers)) {
				if (header.includes("dlna")) continue;
				res.header(header, streamRes.headers[header]);
			}
			let bytes = 0;
			streamRes.on("error", (err) => {
				console.error(err.message);
			});
			streamRes.on("data", (chunk) => {
				bytes += chunk.length;
			});
			streamRes.pipe(res, { end: true });
			streamRes.on("close", () => {
				console.log("Transferred", Math.round(bytes / 1024 / 1024), "MiB");
			});

			req.on("error", (err) => {
				console.error(err.message);
			});
			req.on("close", () => {
				streamRes.destroy();
			});
		});
	}

	if (stream) {
		proxyFile();
	} else {
		stream = new Stream(magnet);
		streams.push(stream);
		stream.once("start", proxyFile);
		stream.init();
	}
}

export function deleteStream(req: express.Request, res: express.Response): void {
	const magnet = atob(req.params.magnetBase64);
	const stream = streams.find((s) => s.magnet === magnet);
	if (stream) {
		stream.delete();
		res.end();
	} else {
		res.sendStatus(404);
	}
}
