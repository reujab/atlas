import cheerio from "cheerio";
import http from "http";
import parseName from "./parse";
import { SocksProxyAgent } from "socks-proxy-agent";

export interface Source {
	name: string;
	score: number;
	seeders: number;
	leechers: number;
	size: number;

	seasons: null | number[];
	episode: null | number;

	element: null | HTMLDivElement;
	getMagnet: () => Promise<string>;
}

export default async function search(query: string, type: string): Promise<Source[]> {
	query = encodeURIComponent(query.replace(/['"]/g, "").replace(/\./g, " "));
	let sources = (await Promise.allSettled([searchPB(query, type), search1337x(query, type)])).filter((p) => {
		if (p.status === "fulfilled") {
			return true;
		}

		console.error(p.reason);

		return false;
	}).map((p: any) => p.value).flat();

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

		console.log(`filtering ${source.name} (${source.seeders})`);
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
			console.log("source doesn't match: %O", source.name);
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
			// eslint-disable-next-line require-await
			getMagnet: async () => `magnet:?xt=urn:btih:${source.info_hash}&dn=${encodeURIComponent(source.name)}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2710%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2780%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2730%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=http%3A%2F%2Fp4p.arenabg.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce`,
			name: source.name,
			seeders: Number(source.seeders),
			leechers: Number(source.leechers),
			size: Number(source.size),
			element: null,
		} as Source));
	}

	return new Promise((resolve, reject) => {
		get(`https://apibay.org/${path}`).then((res) => {
			res.json().then((sources: any) => {
				resolve(parseSources(sources));
			}).catch((err: any) => {
				reject(err);
			});
		}).catch((err: any) => {
			console.error("pb error", err);
			const agent = new SocksProxyAgent({
				hostname: "localhost",
				port: 9050,
			});
			const req = http.get(
				`http://piratebayo3klnzokct3wt5yyxb2vpebbuyjl7m623iaxmqhsd52coid.onion/${path}`,
				{ agent },
				(res) => {
					console.log("headers: %O", res.headers);

					let data = "";
					res.on("data", (chunk) => {
						data += chunk;
					});
					res.on("end", () => {
						try {
							resolve(parseSources(JSON.parse(data)));
						} catch (err) {
							console.log("%O", data);
							console.error("error parsing json", err);
							reject(err);
						}
					});
					res.on("error", (err) => {
						console.error("pb onion error", err);
						reject(err);
					});
				}
			);

			req.on("error", (err) => {
				console.error("socks error", err);
				reject(err);
			});
		});
	});
}

async function search1337x(query: string, type?: string, signal?: AbortSignal): Promise<Source[]> {
	const path = type === "movie" ? `category-search/${query}/Movies/1/` : type === "tv" ? `category-search/${query}/TV/1/` : `search/${query}/1/`;
	let res;
	try {
		res = await get(`https://1337x.to/${path}`, { signal });
	} catch (err) {
		console.error("1337x error", err);
		return [];
	}
	const html = await res.text();
	if (signal?.aborted) {
		throw new DOMException("aborted");
	}
	const $ = cheerio.load(html);
	return Array.from($("tbody > tr")).map((ele) => ({
		getMagnet: (async (p?: string) => {
			const r = await get(`https://1337x.to${p}`);
			// eslint-disable-next-line no-shadow
			const html = await r.text();
			// eslint-disable-next-line no-shadow
			const $ = cheerio.load(html);
			return $("a[href^=magnet:]").attr("href") || "";
		}).bind(null, $(ele).find(".name > a:nth-child(2)").attr("href")),
		name: $(ele).find(".name > a:nth-child(2)").text(),
		seeders: Number($(ele).find("td.seeds").text()),
		leechers: Number($(ele).find("td.leeches").text()),
		size: parseSize($(ele).find("td.size").text().replace(/B.*/, "B")),
		element: null,
		score: 0,
		seasons: null,
		episode: null,
	}));
}

function parseSize(size: string): number {
	const dens = ["KB", "MB", "GB"];
	const [num, den] = size.split(" ");
	const multiplier = 1000 ** (dens.indexOf(den) + 1);
	return Number(num.replace(/,/g, "")) * multiplier;
}


async function get(...args: Parameters<typeof fetch>): Promise<Response> {
	const start = Date.now();
	let lastErr;

	for (let i = 0; i < 4; i++) {
		if (Date.now() - start > 5000) break;

		try {
			console.log(`Getting ${args[0]}`);
			// eslint-disable-next-line no-await-in-loop
			const res = await fetch(...args);
			console.log(`Reply at ${(Date.now() - start) / 1000}s`);

			lastErr = new Error(`Status: ${res.status}`);

			if (res.status >= 500) continue;
			if (res.status !== 200) break;

			return res;
		} catch (err) {
			lastErr = err;

			console.error("Fetch error", err);

			if ((err as Error).message?.startsWith("status:")) break;
		}
	}

	throw lastErr;
}
