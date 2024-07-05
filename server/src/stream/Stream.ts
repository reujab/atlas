import EventEmitter from "events";
import { Server } from "http";
import WebTorrent, { Torrent } from "webtorrent";
import { port } from "..";

export const streams: Stream[] = [];

let webtorrent = new WebTorrent();

export default class Stream extends EventEmitter {
	uuid: string;
	started: boolean = false;
	port: number = 0;
	magnet: string;
	torrent: null | Torrent = null;
	destroyTimeout?: NodeJS.Timeout;

	private server?: Server;
	private logInterval?: NodeJS.Timeout;

	constructor(uuid: string, magnet: string) {
		super();

		this.uuid = uuid;
		this.magnet = magnet;
		this.assignPort();
	}

	assignPort(): void {
		do {
			this.port = port + 1 + Math.floor(1000 * Math.random());
		} while (streams.find((s) => s.port == this.port));
	}

	init(): void {
		console.log("Connecting to", this.magnet);

		this.updateTimeout();

		const start = Date.now();
		this.torrent = webtorrent.add(this.magnet, { destroyStoreOnDestroy: true }, (torrent) => {
			console.log("Connected in %ss", ((Date.now() - start) / 1000).toFixed(2));

			this.logInterval = setInterval(() => {
				console.log("Downloaded %s%", Math.floor(torrent.downloaded / torrent.length * 100));
				if (torrent.downloaded === torrent.length && this.logInterval)
					clearInterval(this.logInterval);
			}, 60_000);

			torrent.on("error", (err) => {
				console.error("Torrent", this.uuid, "encountered a fatal error:", err);
				this.destroy();
			});

			console.log("Files:", torrent.files.map((f) => f.name));
			this.startServer();
		});
	}

	updateTimeout(): void {
		if (this.destroyTimeout)
			clearTimeout(this.destroyTimeout);
		this.destroyTimeout = setTimeout(() => this.destroy(), 60_000);
	}

	private startServer(): void {
		this.server?.close();
		this.server = this.torrent!.createServer();
		this.server.on("error", (err) => {
			console.error("Error starting stream", this.uuid, "on port", this.port + ":", err);
			this.assignPort();
			this.startServer();
		})
		this.server.listen(this.port, "127.0.0.1", undefined, () => {
			this.started = true;
			this.emit("start");
		});
	}

	destroy(): void {
		console.log("Destroying stream", this.uuid);
		const index = streams.indexOf(this);
		if (index === -1) console.error("Stream#destroy called but stream not found");
		else streams.splice(index, 1);
		this.server?.close();
		this.torrent?.destroy();
		if (this.destroyTimeout) clearTimeout(this.destroyTimeout);
		if (this.logInterval) clearInterval(this.logInterval);
	}
}

setInterval(() => {
	if (streams.length)
		console.log(
			"DL:", Math.round(webtorrent.downloadSpeed / 1024), "KiB/s",
			"|",
			"UP:", Math.round(webtorrent.uploadSpeed / 1024), "KiB/s",
		);
}, 10_000);

webtorrent.on("error", (err) => {
	console.error("WebTorrent encountered a fatal error:", err);
	for (const stream of streams) stream.destroy();
	webtorrent = new WebTorrent();
})
