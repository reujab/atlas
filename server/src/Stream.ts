import EventEmitter from "events";
import { Request, Response } from "express";
import http, { Server } from "http";
import WebTorrent, { Torrent, TorrentFile } from "webtorrent";
import parseName from "./parse_name";

const TIMEOUT = 20_000;

const webtorrent = new WebTorrent();

export default class Stream extends EventEmitter {
	port: number;
	type: "movie" | "tv";
	title_id: number;
	seasons: null | number[];
	episode: null | number;
	magnet: string;
	ready = false;

	torrent?: Torrent;
	server?: Server;
	destroyTimeout?: NodeJS.Timeout;

	constructor(
		port: number,
		type: "movie" | "tv",
		title_id: number,
		seasons: null | number[],
		episode: null | number,
		magnet: string,
	) {
		super();
		this.port = port;
		this.type = type;
		this.title_id = title_id;
		this.seasons = seasons;
		this.episode = episode;
		this.magnet = magnet;
	}

	has(type: string, id: number, season: null | number, episode: null | number): boolean {
		return (
			type == this.type &&
			id == this.title_id &&
			(type == "movie" ||
				(this.seasons!.includes(season!) && [episode, null].includes(this.episode!)))
		);
	}

	init(): Promise<void> {
		console.log("Connecting to", this.magnet);
		return new Promise((resolve, reject) => {
			this.resetTimeout();

			const destroyListener = () => reject("Stream was destroyed");
			this.once("destroy", destroyListener);

			const connectionTimeout = setTimeout(() => {
				reject("Connection timed out");
				this.destroy();
			}, TIMEOUT);

			this.torrent = webtorrent.add(this.magnet, { destroyStoreOnDestroy: true }, (torrent) => {
				clearTimeout(connectionTimeout);

				console.log(
					"Files:",
					torrent.files.map((f) => f.name),
				);
				this.startServer()
					.then(() => {
						// Make sure torrent is downloading.
						const timeout = Date.now() + TIMEOUT;
						const interval = setInterval(() => {
							if (torrent.downloaded != 0) {
								clearInterval(interval);
								resolve();
							} else if (Date.now() >= timeout) {
								clearInterval(interval);
								reject(`Stream timed out with ${torrent.numPeers} peers`);
								this.destroy();
							}
						}, 100);
					})
					.catch(reject)
					.finally(() => {
						this.removeListener("destroy", destroyListener);
					});
			});
			this.torrent.on("error", (err) => {
				console.error("Torrent encountered a fatal error:", err);
				reject(err);
				this.destroy();
			});
		});
	}

	resetTimeout(): void {
		if (this.destroyTimeout) clearTimeout(this.destroyTimeout);
		this.destroyTimeout = setTimeout(() => this.destroy(), 60_000);
	}

	private startServer(): Promise<void> {
		return new Promise((resolve, reject) => {
			this.server?.close();
			this.server = this.torrent!.createServer();
			this.server.on("error", (err) => {
				console.error(`Error starting server on port ${this.port}:`, err);
				reject(err);
				this.destroy();
			});
			this.server.listen(this.port, "127.0.0.1", undefined, () => {
				this.ready = true;
				resolve();
			});
		});
	}

	serve(req: Request, res: Response, season: null | number, episode: null | number): void {
		if (req.path == "/keepalive") {
			this.resetTimeout();
			res.status(200).end();
			return;
		}

		if (!this.ready) throw new Error(`Cannot serve ${req.path} before server has started`);

		const file = this.findFile(season, episode);
		if (!file) {
			console.error("Could not find file", season, episode);
			for (const file of this.torrent!.files) {
				console.log(file.name, parseName(file.name));
			}
			res.status(404).end();
			return;
		}

		if (req.path == "/subs") {
			this.serveSubs(req, res, file);
			return;
		}

		this.proxy(req, res, file);
	}

	private findFile(season: null | number, episode: null | number): undefined | TorrentFile {
		// Sort the files by length, preventing sample files from playing instead of the actual
		// video.
		const files = this.torrent!.files.sort((a, b) => b.length - a.length);
		const file = season
			? files.find((f) => {
					const parsed = parseName(f.name);
					return parsed.seasons.includes(Number(season)) && parsed.episode === Number(episode);
			  })
			: files.find((f) => /\.(?:mp4|avi|mkv)$/.test(f.name));
		return file;
	}

	private serveSubs(req: Request, res: Response, file: TorrentFile): void {
		const fileName = file.name.replace(/...$/, "srt");
		const subFile = this.torrent!.files.find((f) => f.name == fileName);
		if (!subFile) {
			res.status(404).end();
			return;
		}
		this.proxy(req, res, subFile);
	}

	private proxy(clientReq: Request, clientRes: Response, file: TorrentFile): void {
		const index = this.torrent!.files.indexOf(file);
		const path = `http://127.0.0.1:${this.port}/${index}/${encodeURIComponent(file.name)}`;
		const proxyReq = http.get(path, { headers: clientReq.headers }, (proxyRes) => {
			for (const header of Object.keys(proxyRes.headers)) {
				if (header.includes("dlna")) continue;
				clientRes.header(header, proxyRes.headers[header]);
			}
			proxyRes.pipe(clientRes, { end: true });
			clientReq.on("close", () => {
				proxyRes.destroy();
			});
		});
		proxyReq.on("error", (err) => {
			console.error("Proxy err:", err);
		});
	}

	destroy(): void {
		console.log("Destroying stream");
		if (this.destroyTimeout) clearTimeout(this.destroyTimeout);
		this.server?.close();
		this.torrent?.destroy();
		this.emit("destroy");
		this.removeAllListeners();
	}
}

setInterval(() => {
	if (!webtorrent.torrents.length) return;
	console.log("DL:", webtorrent.downloadSpeed, "UP:", webtorrent.uploadSpeed);
}, 10_000);
