import { Request, Response } from "express";
import * as main from ".";
import Stream from "./Stream";
import sql from "./sql";

/// StreamManager handles concurrent requests to streams, initializes streams, and tries different
/// sources if one fails.
export default class StreamManager {
	static startingStreams: { [key: string]: Promise<null | Stream> } = {};
	static startedStreams: Stream[] = [];
	static usedPorts: number[] = [];

	static async handleConnection(type: "movie" | "tv", req: Request, res: Response): Promise<void> {
		const id = Number(req.params.id);
		const season = req.params.s ? Number(req.params.s) : null;
		const episode = req.params.e ? Number(req.params.e) : null;
		const stream = await StreamManager.initStream(type, id, season, episode);
		if (!stream) {
			res.status(404).end();
			return;
		}
		stream.serve(req, res, season, episode);
	}

	static initStream(
		type: "movie" | "tv",
		id: number,
		season: null | number,
		episode: null | number,
	): Promise<null | Stream> {
		let stream = StreamManager.startedStreams.find((s) => s.has(type, id, season, episode));
		if (stream) return new Promise((resolve) => resolve(stream!));

		const key = `${type}:${id}:${season}:${episode}`;
		const promise = StreamManager.startingStreams[key];
		if (promise) return promise;

		return (StreamManager.startingStreams[key] = new Promise<null | Stream>(
			async (resolve, reject) => {
				console.log("Creating new stream");

				const sources = await sql`
					SELECT magnet, seasons, episode FROM sources
					WHERE type = ${type} AND id = ${id}
					AND (seasons IS NULL OR ${season} = ANY(seasons))
					AND (episode IS NULL OR episode = ${episode})
					AND NOT defunct
					ORDER BY score DESC
					LIMIT 3
				`;
				if (!sources.length) return resolve(null);

				for (let i = 0; i < sources.length; i++) {
					const source = sources[i];
					const port = StreamManager.assignPort();
					stream = new Stream(port, type, id, source.seasons, source.episode, source.magnet);

					const start = Date.now();
					try {
						await stream.init();
					} catch (err) {
						console.error("Failed to init stream:", err);
						await sql`
							UPDATE sources
							SET defunct = TRUE
							WHERE magnet = ${source.magnet}
						`;
						if (i == sources.length - 1) return reject(err);

						console.log("Trying next source");
						continue;
					}
					console.log("Connected in %ss", ((Date.now() - start) / 1000).toFixed(2));
					StreamManager.startedStreams.push(stream);
					stream.on("destroy", () => {
						const index = StreamManager.startedStreams.indexOf(stream!);
						if (index == -1) console.error("Cannot remove stream: Stream not found.");
						else StreamManager.startedStreams.splice(index, 1);
						StreamManager.unassignPort(port);
					});
					return resolve(stream);
				}
			},
		).finally(() => delete StreamManager.startingStreams[key]));
	}

	private static assignPort(): number {
		let port: number;
		do {
			port = main.port + 1 + Math.floor(1000 * Math.random());
		} while (StreamManager.usedPorts.includes(port));
		StreamManager.usedPorts.push(port);
		return port;
	}

	private static unassignPort(port: number) {
		const index = StreamManager.usedPorts.indexOf(port);
		if (index === -1) console.error("Could not find port", port);
		else StreamManager.usedPorts.splice(index, 1);
	}
}
