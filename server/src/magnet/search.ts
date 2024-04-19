import cheerio from "cheerio";
import http from "http";
import { SocksProxyAgent } from "socks-proxy-agent";
import get from "../get";
import parseName from "./parse_name";

export interface Source {
	source: string;
	name: string;
	score: number;
	seeders: number;
	leechers: number;
	size: number;

	seasons: null | number[];
	episode: null | number;

	getMagnet: () => Promise<string>;
}

export default async function searchMagnets(query: string, type: string): Promise<Source[]> {
	query = encodeURIComponent(query.replace(/['"]/g, "").replace(/\./g, " "));
	let sources = (await Promise.allSettled([searchPB(query, type), search1337x(query, type)]))
		// DEBUG
		.map((p) => { p.status !== "fulfilled" && console.log("p", p); return p; })
		.filter((p) => p.status === "fulfilled")
		.map((p: any) => p.value)
		.flat();

	function simplify(s: string): string {
		return decodeURIComponent(s).replace(/\.|\(/g, " ").split(" ")[0].toLowerCase().replace(/[^a-z0-9]+/g, "");
	}
	sources = sources.filter((source) => {
		if (source.seeders < 5) {
			return false;
		}

		if (simplify(query) === simplify(source.name)) {
			return true;
		}

		console.log(`Filtering ${source.name} (${source.seeders})`);
		return false;
	});

	for (const source of sources) {
		const name = source.name.toLowerCase();
		let score = source.seeders;

		if (name.includes("1080p")) {
			score *= 1.8;
		} else if (name.includes("720p")) {
			score *= 0.8;
		} else if (name.includes("480p")) {
			score *= 0.5;
		}

		if (name.includes("hdcam") || name.includes("camrip") || name.includes("hdts")) {
			score *= 0.2;
		}

		if (name.includes("264") || name.includes("265")) {
			score *= 1.2;
		}

		source.score = score;

		const parsed = parseName(name);
		if (!parsed) {
			console.log("Source doesn't match", source.name);
		}
		Object.assign(source, parsed);
	}
	sources = sources.sort((a, b) => b.score - a.score);
	return sources;
}

function searchPB(query: string, type?: string): Promise<Source[]> {
	const cat = type === "movie" ? "201,207" : type === "tv" ? "205,208" : "200";
	const path = `q.php?cat=${cat}&q=${query}`;

	function parseSources(sources: any): Source[] {
		return sources.map((source: any) => ({
			source: "PB",
			// eslint-disable-next-line require-await
			name: source.name,
			seeders: Number(source.seeders),
			leechers: Number(source.leechers),
			size: Number(source.size),
			getMagnet: async () => `magnet:?xt=urn:btih:${source.info_hash}&dn=${encodeURIComponent(source.name)}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2710%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2780%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2730%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=http%3A%2F%2Fp4p.arenabg.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce`,
		}));
	}

	return new Promise((resolve, reject) => {
		get(`https://apibay.org/${path}`).then((res) => {
			res.json().then((sources: any) => {
				resolve(parseSources(sources));
			}).catch((err: any) => {
				console.error("Error getting json:", err);
				reject(err);
			});
		}).catch((err: any) => {
			console.error("PB error:", err);
			const agent = new SocksProxyAgent({
				hostname: "localhost",
				port: 9050,
			});
			const req = http.get(
				`http://piratebayo3klnzokct3wt5yyxb2vpebbuyjl7m623iaxmqhsd52coid.onion/${path}`,
				{ agent },
				(res) => {
					console.log("Connected to onion");

					let data = "";
					res.on("data", (chunk) => {
						data += chunk;
					});
					res.on("end", () => {
						try {
							resolve(parseSources(JSON.parse(data)));
						} catch (err) {
							console.log("%O", data);
							console.error("Error parsing json:", err);
							reject(err);
						}
					});
				}
			);

			req.on("error", (err) => {
				console.error("Socks error:", err);
				reject(err);
			});
		});
	});
}

async function search1337x(query: string, type?: string): Promise<Source[]> {
	const path = type === "movie"
		? `category-search/${query}/Movies/1/`
		: type === "tv" ? `category-search/${query}/TV/1/` : `search/${query}/1/`;
	const res = await get(`https://1337x.to/${path}`);
	const html = await res.text();
	const $ = cheerio.load(html);
	return Array.from($("tbody > tr")).map((ele) => ({
		source: "1337x",
		name: $(ele).find(".name > a:nth-child(2)").text(),
		seeders: Number($(ele).find("td.seeds").text()),
		leechers: Number($(ele).find("td.leeches").text()),
		size: parseSize($(ele).find("td.size").text().replace(/B.*/, "B")),
		score: 0,
		seasons: null,
		episode: null,
		getMagnet: (async (p?: string) => {
			const r = await get(`https://1337x.to${p}`);
			// eslint-disable-next-line no-shadow
			const html = await r.text();
			// eslint-disable-next-line no-shadow
			const $ = cheerio.load(html);
			return $("a[href^=magnet:]").attr("href") || "";
		}).bind(null, $(ele).find(".name > a:nth-child(2)").attr("href")),
	}));
}

function parseSize(size: string): number {
	const dens = ["KB", "MB", "GB"];
	const [num, den] = size.split(" ");
	const multiplier = 1000 ** (dens.indexOf(den) + 1);
	return Number(num.replace(/,/g, "")) * multiplier;
}
