import { Request, Response } from "express";
import { streams } from "./Stream";

export async function keepalive(req: Request, res: Response): Promise<void> {
	const uuid = req.params.uuid;
	const stream = streams.find((stream) => stream.uuid == uuid);

	if (!stream) {
		// Don't reinitialize the stream here because it's not necessary. If the stream was
		// destroyed for any reason, it will be reinitialized on a GET to /stream.
		res.status(404).end();
		return;
	}

	stream.updateTimeout();
	res.status(200).end();
}
