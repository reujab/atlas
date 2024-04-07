import EventEmitter from "events";
import express from "express";
import http from "http";
import WebTorrent from "webtorrent";
import parseName from "./parse";
import sql from "./sql";

const webtorrent = new WebTorrent({
	uploadLimit: 0.25 * 1024 * 1024,
} as any);
const maxStreams = 10;
const streams: Stream[] = [];

let streamID = -1;
class Stream extends EventEmitter {
	id: number;

	port: number;

	uuid: string;

	magnet: string;

	torrent: null | WebTorrent.Torrent = null;

	destroyTimeout: null | NodeJS.Timeout = null;

	private server: null | http.Server = null;

	private logInterval: null | NodeJS.Timer = null;

	constructor(uuid: string, magnet: string) {
		super();
		do {
			this.id = streamID = (streamID + 1) % maxStreams;
		} while (streams.find((s) => s.id === this.id)); // eslint-disable-line
		this.port = 1 + Number(process.env.PORT) + this.id;
		this.uuid = uuid;
		this.magnet = magnet;
	}

	init(): void {
		console.log("Connecting to", this.magnet);
		this.updateDestroyTimeout();
		const then = Date.now();
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
			this.server.on("error", (err) => {
				console.error(err);
			});
			this.server.listen(this.port, "127.0.0.1", undefined, () => {
				this.emit("start");
			});
		});
	}

	updateDestroyTimeout(): void {
		if (this.destroyTimeout) {
			clearTimeout(this.destroyTimeout);
		}
		this.destroyTimeout = setTimeout(() => this.destroy(), 10_000);
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

export async function init(req: express.Request, res: express.Response): Promise<void> {
	if (streams.length >= maxStreams) {
		res.status(500).end("Too many active streams");
		return;
	}

	const uuid = req.query.uuid as string;
	const season = req.query.s as string;
	const episode = req.query.e as string;

	if (!uuid) {
		res.status(400).end();
		return;
	}

	const row = await sql`
		SELECT magnet FROM magnets
		WHERE uuid = ${uuid}
		LIMIT 1
	`;
	if (!row.length) {
		res.status(404).end();
		return;
	}
	const magnet = row[0].magnet;

	const existingStream = streams.find((s) => s.magnet === magnet);
	if (existingStream) {
		if (existingStream.torrent) {
			serveInfo(res, existingStream, season, episode);
		} else {
			// Poll until torrent is initialized. Timeout after one minute.
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
	const stream = new Stream(uuid, magnet);
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
	const base = `/stream/${stream.uuid}`;
	const file = stream.torrent.files[index];
	const filePath = `${base}/${index}/${encodeURIComponent(file.name)}`;
	const subs = stream.torrent.files.find((s) => s.name === file.name.replace(/...$/, "srt"));
	const subsPath = subs ? `${base}/${stream.torrent.files.indexOf(subs)}/${encodeURIComponent(subs.name)}` : null;
	res.json({
		video: filePath,
		subs: subsPath,
	});
}

function findFile(torrent: WebTorrent.Torrent, season?: string, episode?: string): number {
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

export async function proxy(req: express.Request, res: express.Response): Promise<void> {
	req.setTimeout(3 * 60 * 1000);
	const uuid = req.params.uuid;
	let stream = streams.find((s) => s.uuid === uuid);

	function proxyFile(): void {
		if (!stream) throw new Error();
		const path = `http://127.0.0.1:${stream.port}${req.path}`;
		const proxyReq = http.get(path, { headers: req.headers }, (streamRes) => {
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
		proxyReq.on("error", (err) => {
			console.error("proxy req err:", err);
		});
	}

	if (stream) {
		proxyFile();
	} else {
		const row = await sql`
			SELECT magnet FROM magnets
			WHERE uuid = ${uuid}
			LIMIT 1;
		`;
		if (!row.length) {
			res.status(404).end();
			return;
		}
		const magnet = row[0].magnet;
		// eslint-disable-next-line require-atomic-updates
		stream = new Stream(uuid, magnet);
		streams.push(stream);
		stream.once("start", proxyFile);
		stream.init();
	}
}

export async function keepalive(req: express.Request, res: express.Response): Promise<void> {
	const uuid = req.params.uuid;
	const stream = streams.find((stream) => stream.uuid == uuid);

	if (!stream) {
		res.status(404).end();
		return;
	}

	stream.updateDestroyTimeout();
	res.status(200).end();
}
