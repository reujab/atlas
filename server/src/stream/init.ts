import { Request, Response } from "express";
import sql from "../sql";
import Stream, { streams } from "./Stream";
import serveInfo from "./serve_info";

const maxStreams = 2;

/** Starts downloading the magnet and sends information about the stream. */
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
		if (existingStream.started) {
			serveInfo(res, existingStream, season, episode);
		} else {
			existingStream.once("start", () => {
				serveInfo(res, existingStream, season, episode);
			});
		}
		return;
	}

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
	stream.on("start", () => {
		serveInfo(res, stream, season, episode);
	});
	stream.init();
}
