import cheerio from "cheerio";
import { error } from "../log"

export interface Source {
	getMagnet: () => Promise<string>;
	name: string;
	seeders: number;
	leechers: number;
	size: number;
	element: null | HTMLDivElement;
}

export default async function search(query: string): Promise<Source[]> {
	query = encodeURIComponent(query.replace(/['"]/g, "").replace(/\./g, " "));
	let sources: Source[] = [];
	for (const res of await Promise.all([searchPB(query), search1337x(query)])) {
		sources = sources.concat(res);
	}
	return sources.sort((a, b) => b.seeders - a.seeders);
}

async function searchPB(query: string): Promise<Source[]> {
	try {
		const path = `q.php?cat=200&q=${query}`;
		const res = await fetch(`https://apibay.org/${path}`);
		const sources = await res.json();
		return sources.map((source: any) => ({
			getMagnet: async () => {
				return `magnet:?xt=urn:btih:${source.info_hash}&dn=${encodeURIComponent(source.name)}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2710%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2780%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2730%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=http%3A%2F%2Fp4p.arenabg.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce`;
			},
			name: source.name,
			seeders: Number(source.seeders),
			leechers: Number(source.leechers),
			size: Number(source.size),
			element: null,
		} as Source));
	} catch (err) {
		error("error searching pb: %O", err);
		return [];
	}
}

async function search1337x(query: string): Promise<Source[]> {
	try {
		const path = `search/${query}/1/`;
		const res = await fetch(`https://1337x.to/${path}`);
		const html = await res.text();
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
		}));
	} catch (err) {
		error("error searching 1337x: %O", err);
		return [];
	}
}

function parse_size(size: string): number {
	const dens = ["KB", "MB", "GB"];
	const [num, den] = size.split(" ");
	const multiplier = 1000 ** (dens.indexOf(den) + 1);
	return Number(num.replace(/,/g, "")) * multiplier;
}
