import cheerio from "cheerio";
import http from "http";
import { SocksProxyAgent } from "socks-proxy-agent";
import { get } from "..";
import { log, error } from "../log";

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

export interface ParsedName {
	seasons: null | number[];
	episode: null | number;
}

export const episodeRegex = /\b(?:seasons?|s)[ .]*([\d s.,&-]+).*?(?:(?:episode|ep?)[ .]*(\d+))?/i;

export function parseName(name: string): null | ParsedName {
	const match = name.match(episodeRegex);
	if (!match) return null;

	const seasons = match[1]
		.replace(/[ .,&s-]+/gi, " ")
		.trim()
		.split(" ")
		.map(Number)
		.filter((s) => s < 256);
	if (seasons.length === 2) {
		for (let i = seasons[0] + 1; i < seasons[1]; i++) {
			seasons.push(i);
		}
	}
	const episode = Number(match[2]) || null;
	return { seasons, episode };
}

export default async function search(query: string, type?: "movie" | "tv", signal?: AbortSignal): Promise<Source[]> {
	query = encodeURIComponent(query.replace(/['"]/g, "").replace(/\./g, " "));
	let sources = (await Promise.all([searchPB(query, type, signal), search1337x(query, type, signal)])).flat();

	function simplify(s: string): string {
		return decodeURIComponent(s).replace(/\.|\(/g, " ").split(" ")[0].toLowerCase().replace(/[^a-z0-9]+/g, "");
	}
	sources = sources.filter((source) => {
		if (simplify(query) === simplify(source.name)) {
			return true;
		}

		log(`filtering ${source.name} (${source.seeders})`);
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

		if (name.includes("hdcam") || name.includes("camrip")) {
			score *= 0.5;
		}

		if (name.includes("264") || name.includes("265")) {
			score *= 1.2;
		}

		source.score = score;

		const parsed = parseName(name);
		if (parsed) {
			log("%O %O %O", source.name, source.seeders, parsed);
		} else {
			log("source doesn't match: %O", source.name);
		}
		Object.assign(source, parsed);
	}
	sources = sources.sort((a, b) => b.score - a.score);
	return sources;
}

function searchPB(query: string, type?: "movie" | "tv", signal?: AbortSignal): Promise<Source[]> {
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
		get(`https://apibay.org/${path}`, { signal }).then((res) => {
			res.json().then((sources: any) => {
				resolve(parseSources(sources));
			}).catch((err) => {
				reject(err);
			});
		}).catch((err) => {
			if (signal?.aborted) {
				reject(err);
				return;
			}

			error("pb error", err);
			const agent = new SocksProxyAgent({
				hostname: "localhost",
				port: 9050,
			});
			const req = http.get(
				`http://piratebayo3klnzokct3wt5yyxb2vpebbuyjl7m623iaxmqhsd52coid.onion/${path}`,
				{ agent },
				(res) => {
					log("headers: %O", res.headers);

					let data = "";
					res.on("data", (chunk) => {
						if (signal?.aborted) {
							reject(new DOMException("aborted"));
							res.destroy();
							return;
						}
						data += chunk;
					});
					res.on("end", () => {
						if (signal?.aborted) {
							reject(new DOMException("aborted"));
							return;
						}
						try {
							resolve(parseSources(JSON.parse(data)));
						} catch (err) {
							log("%O", data);
							error("error parsing json", err);
							reject(err);
						}
					});
					res.on("error", (err) => {
						error("pb onion error", err);
						reject(err);
					});
				}
			);

			req.on("error", (err) => {
				error("socks error", err);
				reject(err);
			});
		});
	});
}

async function search1337x(query: string, type?: "movie" | "tv", signal?: AbortSignal): Promise<Source[]> {
	const path = type === "movie" ? `category-search/${query}/Movies/1/` : type === "tv" ? `category-search/${query}/TV/1/` : `search/${query}/1/`;
	let res;
	try {
		res = await get(`https://1337x.to/${path}`, { signal });
	} catch (err) {
		error("1337x error", err);
		return [];
	}
	const html = await res.text();
	if (signal?.aborted) {
		throw new DOMException("aborted");
	}
	const $ = cheerio.load(html);
	return Array.from($("tbody > tr")).map((ele) => ({
		getMagnet: (async (p: string) => {
			const r = await get(`https://1337x.to${p}`);
			// eslint-disable-next-line no-shadow
			const html = await r.text();
			// eslint-disable-next-line no-shadow
			const $ = cheerio.load(html);
			return $("a[href^=magnet:]").attr("href");
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
