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

const db = `${process.env.SEEDBOX_HOST}:${process.env.SEEDBOX_PORT}`;

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
	const res = await get(`${db}/${type}/rows`);
	const rows = await res.json();
	for (const row of rows) {
		row.titles = cacheTitles(row.titles);
		row.activeCol = 0;
		row.element = null;
	}
	return rows;
}

export async function getSeasons(title: Title): Promise<Season[]> {
	return (await get(`${db}/seasons/${title.id}`)).json();
}

export async function getAutocomplete(query: string, blacklist: number[] = []): Promise<null | Title[]> {
	const res = await get(`${db}/search?q=${encodeURIComponent(query)}&blacklist=${blacklist.join(",")}`);
	const titles = await res.json();
	return cacheTitles(titles, false);
}

progress.subscribe((p) => {
	localStorage.progress = JSON.stringify(p);
});
