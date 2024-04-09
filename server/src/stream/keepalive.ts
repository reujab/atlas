import { Request, Response } from "express";
import { streams } from "./Stream";

export async function keepalive(req: Request, res: Response): Promise<void> {
	const uuid = req.params.uuid;
	const stream = streams.find((stream) => stream.uuid == uuid);

	if (!stream) {
		res.status(404).end();
		return;
	}

	stream.updateTimeout();
	res.status(200).end();
}
