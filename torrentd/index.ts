import WebTorrent from "webtorrent";
import child_process from "child_process";
import net from "net";

interface Info {
	title: null | string,
	buffered: null | number,
}

const server = net.createServer();
const webtorrent = new WebTorrent();
const torrentPath = `${process.env.HOME}/Downloads`;
const clients: net.Socket[] = [];
let currentTorrent: null | WebTorrent.Torrent = null;
let mpv: null | child_process.ChildProcess = null;
let info: Info = {
	title: null,
	buffered: null,
};

server.listen("/tmp/torrentd", () => {
	console.log("Started");
});

server.on("connection", (socket) => {
	console.log("New connection");

	clients.push(socket);

	socket.on("error", (err) => {
		console.error(err);
	});

	socket.on("close", () => {
		console.log("Connection closed");
		clients.splice(clients.indexOf(socket), 1);
	});

	socket.on("data", (chunk) => {
		console.log(`${chunk}`);

		let data;
		try {
			data = JSON.parse(chunk.toString());
		} catch (err) {
			console.error(`Could not parse: ${chunk}`);
			socket.destroy();
			return;
		}

		switch (data.message) {
			case "play":
				play(data.magnet, data.file);
				break;
			case "get_info":
				socket.write(JSON.stringify(Object.assign({
					message: "info",
					speed: Math.floor(webtorrent.downloadSpeed),
				}, info)));
				break;
			case "stop":
				mpv?.kill();
				currentTorrent?.destroy();
				currentTorrent = null;
				break;
			default:
				console.error("unknown message:", data.message);
		}
	});
});

function play(magnet: string, fileName?: string) {
	currentTorrent = webtorrent.add(magnet, { path: torrentPath }, (torrent) => {
		console.log("Connected");

		torrent.on("error", (err) => {
			console.error(err);
		});

		const index = fileName ?
			torrent.files.findIndex((file) => file.name === fileName) :
			torrent.files
				.map((file, originalIndex) => ({ file, originalIndex }))
				.sort((a, b) => b.file.length - a.file.length)
				.find((f) => /\.(mp4|avi|mkv)$/.test(f.file.name))?.originalIndex;
		if (index === undefined || index === -1) {
			console.error("File not found");
			currentTorrent = null;
			torrent.destroy();
			emit({ message: "player_closed" });
			return;
		}

		const file = torrent.files[index];
		info.title = file.name;
		console.log(`Selecting "${file.name}"`);
		file.select();

		const interval = setInterval(() => {
			info.buffered = file.progress;
		}, 1000);

		const torrentServer = torrent.createServer();
		torrentServer.listen(8000);

		mpv = child_process.spawn("mpv", ["--audio-device=alsa/hdmi:CARD=PCH,DEV=0", "--save-position-on-quit", `http://localhost:8000/${index}/${encodeURIComponent(file.name)}`], {
			stdio: "inherit",
		});

		mpv.on("error", (err) => {
			console.error(err);
		});

		mpv.on("exit", (code) => {
			console.log("mpv exit code:", code);

			currentTorrent = null;
			mpv = null;
			info = {
				title: null,
				buffered: null,
			};
			torrentServer.close();
			torrent.destroy();
			clearInterval(interval);
			emit({ message: "player_closed" });
		});
	});
}

function emit(message: any) {
	for (const client of clients) {
		client.write(JSON.stringify(message));
	}
}
