import net from "net";
import readline from "readline";
import { EventEmitter } from "events";
import { log, error } from "./log";

class TorrentdEmitter extends EventEmitter {
	send: (msg: any) => void;
}

class State {
	torrentdSocket: net.Socket = new net.Socket();

	torrentd: TorrentdEmitter = new TorrentdEmitter();

	reader: null | readline.Interface = null;

	constructor() {
		this.init();
		this.torrentd.send = (msg: any) => {
			this.torrentdSocket.write(`${JSON.stringify(msg)}\n`);
		};
	}

	init(): void {
		this.reader?.close();

		this.torrentdSocket.on("error", (err: any) => {
			if (err.code !== "ENOENT") error("torrentd socket", err);
		});

		this.torrentdSocket.connect("/tmp/torrentd", () => {
			log("Connected to torrentd");
		});

		this.torrentdSocket.on("close", () => {
			error("Socket closed. Reconnecting");
			setTimeout(() => {
				this.torrentdSocket = new net.Socket();
				this.init();
			}, 5000);
		});

		this.reader = readline.createInterface({
			input: this.torrentdSocket,
		});

		this.reader.on("error", (err) => {
			if (err.code !== "ENOENT") error("reader", err);
		});

		this.reader.on("line", (line) => {
			try {
				const msg = JSON.parse(line);
				log("torrentd: %O", msg);
				this.torrentd.emit("message", msg);
			} catch (err) {
				error("torrentd msg", err);
			}
		});
	}
}

export default new State();
