import net from "net";
import readline from "readline";
import { EventEmitter } from "events";
import { log, error } from "./log";

export default new class Torrentd extends EventEmitter {
	private socket: net.Socket = new net.Socket();

	private reader: readline.Interface = readline.createInterface({ input: this.socket });

	constructor() {
		super();
		this.init();
	}

	init(): void {
		this.socket.on("error", (err: any) => {
			if (err.code !== "ENOENT") error("torrentd socket", err);
		});

		this.socket.connect("/tmp/torrentd", () => {
			log("Connected to torrentd");
		});

		this.socket.once("close", () => {
			error("Socket closed. Reconnecting");
			setTimeout(() => {
				this.reader.close();
				this.socket = new net.Socket();
				this.reader = readline.createInterface({ input: this.socket });
				this.init();
			}, 5000);
		});

		this.reader.on("error", (err: any) => {
			if (err.code !== "ENOENT") error("torrentd reader", err);
		});

		this.reader.on("line", (line) => {
			try {
				const msg = JSON.parse(line);
				log("torrentd: %O", msg);
				this.emit("message", msg);
			} catch (err) {
				error("torrentd msg", err);
			}
		});
	}

	send(msg: any): void {
		this.socket.write(`${JSON.stringify(msg)}\n`);
	}
}();
