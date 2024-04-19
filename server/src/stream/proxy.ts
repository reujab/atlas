import { Request, Response } from "express";
import http from "http";
import sql from "../sql";
import Stream, { streams } from "./Stream";

export async function proxy(req: Request, res: Response): Promise<void> {
	req.setTimeout(3 * 60 * 1000);

	const uuid = req.params.uuid;
	let stream = streams.find((s) => s.uuid === uuid);

	if (stream) {
		proxyFile(req, res, stream);
		return;
	}

	// Try to reinitialize the stream if it was accidentally destroyed.
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
	stream = new Stream(uuid, magnet);
	streams.push(stream);
	stream.once("start", () => proxyFile(req, res, stream!));
	stream.init();
}

function proxyFile(clientReq: Request, clientRes: Response, stream: Stream): void {
	const path = `http://127.0.0.1:${stream.port}${clientReq.path}`;
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
