import { log, error } from "./log";
import net from "net";

class State {
	torrentdSocket: net.Socket = new net.Socket();

	constructor() {
		this.init();
	}

	init() {
		this.torrentdSocket.on("error", (err) => {
			error("torrentd err: %O", err);
		});

		this.torrentdSocket.connect("/tmp/torrentd", () => {
			log("Connected to torrentd");
		});

		this.torrentdSocket.on("data", (chunk) => {
			try {
				console.log(JSON.parse(`${chunk}`));
			} catch (err) {
				console.error(err);
				console.log(`${chunk}`);
			}
		});

		this.torrentdSocket.on("close", () => {
			error("Socket closed. Reconnecting");
			setTimeout(() => {
				this.torrentdSocket = new net.Socket();
				this.init();
			}, 1000);
		});
	}
}

export default new State();
