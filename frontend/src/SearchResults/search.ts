import cheerio from "cheerio";
import http from "http";
import { SocksProxyAgent } from "socks-proxy-agent";
import { log, error } from "../log"
import { fetchJSON } from "..";

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
			score *= 2;
		} else if (name.includes("720p")) {
			score *= 0.5;
		} else if (name.includes("480p")) {
			score *= 0.3;
		}

		if (name.includes("bluray") || name.includes("brrip") || name.includes("bdrip")) {
			score *= 1.5;
		} else if (name.includes("web") || name.includes("hdrip")) {
			score *= 1.4;
		} else if (name.includes("hdcam") || name.includes("camrip")) {
			score *= 0.5;
		}

		if (name.includes("264") || name.includes("265")) {
			score *= 1.2;
		}

		source.score = score;

		const match = name.match(/\b(?:seasons?|s)[ .]*(\d+)[ .,&s-]*(?:\d+0p)?(\d+)?[ .]*(?:(?:episode|ep?)[ .]*(\d+))?/);
		if (match) {
			log("%O %O %O %O %O", source.name, source.seeders, match[1], match[2] || null, match[3] || null)
			const season = Number(match[1]);
			const seasonRangeLast = Number(match[2]) || season;
			if (season > seasonRangeLast) {
				continue;
			}
			source.seasons = [...Array(seasonRangeLast - season + 1).keys()].map((i) => i + season);
			source.episode = Number(match[3]) || null;
		} else {
			log("source doesn't match: %O", source.name);
		}
	}
	sources = sources.sort((a, b) => b.score - a.score);
	return sources;
}

function searchPB(query: string, type?: "movie" | "tv", signal?: AbortSignal): Promise<Source[]> {
	const cat = type === "movie" ? "201,207" : type === "tv" ? "205,208" : "200"
	const path = `q.php?cat=${cat}&q=${query}`;

	function parseSources(sources: any): Source[] {
		return sources.map((source: any) => ({
			getMagnet: async () => `magnet:?xt=urn:btih:${source.info_hash}&dn=${encodeURIComponent(source.name)}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2710%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2780%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2730%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=http%3A%2F%2Fp4p.arenabg.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce`,
			name: source.name,
			seeders: Number(source.seeders),
			leechers: Number(source.leechers),
			size: Number(source.size),
			element: null,
		} as Source));
	}

	return new Promise((resolve, reject) => {
		fetchJSON(`https://apibay.org/${path}`, signal).then((sources) => {
			resolve(parseSources(sources));
		}).catch((err) => {
			if (signal?.aborted) {
				reject(err);
				return;
			}

			error("error searching pb: %O", err);
			const agent = new SocksProxyAgent({
				hostname: "localhost",
				port: 9050,
			});
			http.get(
				`http://piratebayo3klnzokct3wt5yyxb2vpebbuyjl7m623iaxmqhsd52coid.onion/${path}`,
				{ agent },
				(res) => {
					log("%O", res.headers);

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
							error("error parsing json: %O", err);
							reject(err);
						}
					});
					res.on("error", (err) => {
						error("pb onion err: %O", err);
						reject(err);
					});
				}
			);
		});
	});
}

async function search1337x(query: string, type?: "movie" | "tv", signal?: AbortSignal): Promise<Source[]> {
	const path = type === "movie" ? `category-search/${query}/Movies/1/` : type === "tv" ? `category-search/${query}/TV/1/` : `search/${query}/1/`;
	const res = await fetch(`https://1337x.to/${path}`, { signal });
	const html = await res.text();
	if (signal?.aborted) {
		throw new DOMException("aborted");
	}
	const $ = cheerio.load(html);
	return Array.from($("tbody > tr")).map((ele) => ({
		getMagnet: (async (path: string) => {
			const res = await fetch(`https://1337x.to${path}`);
			const html = await res.text();
			const $ = cheerio.load(html);
			return $("a[href^=magnet:]").attr("href");
		}).bind(null, $(ele).find(".name > a:nth-child(2)").attr("href")),
		name: $(ele).find(".name > a:nth-child(2)").text(),
		seeders: Number($(ele).find("td.seeds").text()),
		leechers: Number($(ele).find("td.leeches").text()),
		size: parse_size($(ele).find("td.size").text().replace(/B.*/, "B")),
		element: null,
		score: 0,
		seasons: null,
		episode: null,
	}));
}

function parse_size(size: string): number {
	const dens = ["KB", "MB", "GB"];
	const [num, den] = size.split(" ");
	const multiplier = 1000 ** (dens.indexOf(den) + 1);
	return Number(num.replace(/,/g, "")) * multiplier;
}
