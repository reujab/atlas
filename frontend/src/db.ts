import { error } from "./log";
import { get } from ".";
import { writable, Writable } from "svelte/store";

export type TitleType = "movie" | "tv";

export interface Title {
	type: TitleType;
	id: number;
	title: string;
	genres: number[];
	overview: string;
	released: Date;
	trailer: string | null;
	rating: null | string;
	poster: string;
	posterImg: HTMLImageElement;
}

export interface Genre {
	genre: string;
	titles: Title[];
}

export interface Row {
	name: string;
	titles: Title[];

	activeCol: number;
	element: null | HTMLDivElement;
}

export interface Season {
	number: number;
	episodes: Episode[];
	activeEpisode: number;
	ele: null | HTMLDivElement;
	episodesEle: null | HTMLDivElement;
}

export interface Episode {
	number: number;
	date: Date;
	name: string;
	overview: string;
	runtime: number;
	still: string;
	ele: null | HTMLDivElement;

	magnet: undefined | null | string;
}

export interface Magnet {
	magnet: string;
	seasons: number[];
}

const host = process.env.SEEDBOX_HOST;
const key = process.env.SEEDBOX_KEY;

export const cache: { [type: string]: { [id: number]: Title } } = {
	movie: {},
	tv: {},
};

export const progress: Writable<{ [type: string]: { [id: string]: number | string } }> = writable(localStorage.progress ? JSON.parse(localStorage.progress) : {
	movie: {},
	tv: {},
});

export function cacheTitles(titles: Title[], delay?: boolean): Title[] {
	return titles.map((title, i) => {
		if (cache[title.type][title.id])
			return cache[title.type][title.id];
		cache[title.type][title.id] = title;
		title.released = new Date(title.released);
		title.posterImg = new Image();
		title.posterImg.className = "rounded-md";
		title.posterImg.addEventListener("error", (err) => {
			error("Failed to load poster", err);
		});

		function setSrc(): void {
			title.posterImg.src = `https://image.tmdb.org/t/p/w300_and_h450_bestv2${title.poster}`;
		}
		if (delay === undefined || delay === true) {
			setTimeout(setSrc, i * 100);
		} else {
			setSrc();
		}
		return title;
	});
}

export async function getRows(type: TitleType): Promise<Row[]> {
	const res = await get(`${host}/${type}/rows?key=${key}`);
	const rows = await res.json();
	for (const row of rows) {
		row.titles = cacheTitles(row.titles);
		row.activeCol = 0;
		row.element = null;
	}
	return rows;
}

export async function getSeasons(title: Title): Promise<Season[]> {
	return (await get(`${host}/seasons/${title.id}?key=${key}`)).json();
}

export async function getAutocomplete(query: string, blacklist: number[] = []): Promise<null | Title[]> {
	const res = await get(`${host}/search?q=${encodeURIComponent(query)}&blacklist=${blacklist.join(",")}&key=${key}`);
	const titles = await res.json();
	return cacheTitles(titles, false);
}

export async function getMagnet(type: TitleType, query: string, s?: number, e?: number): Promise<null | Magnet> {
	try {
		const res = await get(
			`${host}/${type}/magnet?q=${encodeURIComponent(query)}${type === "tv" ? `&s=${s}&e=${e}` : ""}&key=${key}`
		);
		return res.json();
	} catch (err) {
		return null;
	}
}

export async function getStream(magnet: string, s?: number, e?: number): Promise<string> {
	const path = `${host}/stream?magnet=${encodeURIComponent(
		magnet
	)}${s ? `&s=${s}&e=${e}` : ""}&key=${key}`;
	const res = await get(path);
	const stream = await res.text();
	return `${host}${stream}?key=${key}`;
}

progress.subscribe((p) => {
	localStorage.progress = JSON.stringify(p);
});
