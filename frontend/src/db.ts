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

const db = `${process.env.SEEDBOX_HOST}:8000`;

export const cache: { [type: string]: { [id: number]: Title } } = {
	movie: {},
	tv: {},
};

export const progress: Writable<{ [type: string]: { [id: string]: number } }> = writable(localStorage.progress ? JSON.parse(localStorage.progress) : {
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

export async function getTrending(type: TitleType): Promise<Title[]> {
	const res = await get(`${db}/${type}/trending`);
	const trending = await res.json();
	return cacheTitles(trending);
}

export async function getTopRated(type: TitleType): Promise<Title[]> {
	const res = await get(`${db}/${type}/top`);
	const topRated = await res.json();
	return cacheTitles(topRated);
}

export async function getGenres(type: TitleType): Promise<Genre[]> {
	const res = await get(`${db}/${type}/genres`);
	const genres = await res.json();
	for (const genre of genres) {
		genre.titles = cacheTitles(genre.titles);
	}
	return genres;
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
