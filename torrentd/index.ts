import WebTorrent from "webtorrent";
import childProcess from "child_process";
import net from "net";
import readline from "readline";

interface Info {
	buffered: null | number
}

const server = net.createServer();
const webtorrent = new WebTorrent();
const torrentPath = `${process.env.HOME}/Downloads`;
const clients: net.Socket[] = [];
let currentTorrent: null | WebTorrent.Torrent = null;
let mpv: null | childProcess.ChildProcess = null;
let info: Info = {
	buffered: null,
};

server.listen("/tmp/torrentd", () => {
	console.log("Started");
});

server.on("error", (err) => {
	console.error(err);
});

server.on("connection", (socket) => {
	console.log("New connection");

	clients.push(socket);

	const reader = readline.createInterface({ input: socket });

	socket.on("error", (err: any) => {
		console.error(err.code);
	});

	socket.once("close", () => {
		console.log("Connection closed");
		clients.splice(clients.indexOf(socket), 1);
		reader.close();
	});

	reader.on("error", (err) => {
		console.error(err);
	});

	reader.on("line", (line) => {
		let data;
		try {
			data = JSON.parse(line);
		} catch (err) {
			console.error(`Could not parse: ${line}`);
			socket.destroy();
			return;
		}

		switch (data.message) {
			case "play":
				play(data.magnet, data.file);
				break;
			case "get_info":
				socket.write(`${JSON.stringify({
					message: "info",
					peers: currentTorrent?.numPeers,
					speed: Math.floor(webtorrent.downloadSpeed),
					...info,
				})}\n`);
				break;
			case "stop":
				mpv?.kill();
				currentTorrent?.destroy();
				currentTorrent = null;
				break;
			default:
				console.error("unknown message:", data);
		}
	});
});

function emit(message: any): void {
	for (const client of clients) {
		client.write(`${JSON.stringify(message)}\n`);
	}
}

function play(magnet: string, fileName?: string): void {
	console.log("Connecting");

	currentTorrent = webtorrent.add(magnet, { path: torrentPath }, (torrent) => {
		console.log("Connected");

		/* eslint-disable-next-line */
		let torrentServer: any, interval: NodeJS.Timer;

		function cleanup(): void {
			currentTorrent = null;
			mpv = null;
			info = {
				buffered: null,
			};
			torrentServer?.close();
			torrent.destroy();
			clearInterval(interval);
			emit({ message: "player_closed" });
		}

		torrent.on("error", (err) => {
			console.error(err);
		});

		const index = fileName ?
			torrent.files.findIndex((file) => file.name === fileName) :
			torrent.files.
				map((file, originalIndex) => ({ file, originalIndex })).
				sort((a, b) => b.file.length - a.file.length).
				find((f) => /\.(?:mp4|avi|mkv)$/.test(f.file.name))?.originalIndex;
		if (index === undefined || index === -1) {
			console.error("File not found");
			cleanup();
			return;
		}

		const file = torrent.files[index];
		console.log(`Selecting "${file.name}"`);
		file.select();

		interval = setInterval(() => {
			info.buffered = file.progress;
		}, 1000);

		torrentServer = torrent.createServer();
		torrentServer.listen(8000, "127.0.0.1", undefined, () => {
			if (!currentTorrent) {
				cleanup();
				return;
			}

			mpv = childProcess.spawn("mpv", [
				"--audio-device=alsa/hdmi:CARD=PCH,DEV=0",
				"--input-ipc-server=/tmp/mpv",
				"--save-position-on-quit",
				"--network-timeout=300",
				`http://localhost:8000/${index}/${encodeURIComponent(file.name)}`,
			], { stdio: "inherit" });

			mpv.on("error", (err) => {
				console.error(err);
			});

			mpv.on("exit", (code) => {
				console.log("mpv exit code:", code);
				cleanup();
			});
		});
	});
}
