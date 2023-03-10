import Row from "./Row";
import { getTrending, getTopRated, getGenres, TitleType, cacheTitles } from "../db";
import { writable } from "svelte/store";

class State {
	ready = writable(false);

	rows = writable([
		new Row("Downloaded"),
		new Row("Trending"),
		new Row("Top rated"),
	]);

	activeRow = 0;

	constructor(type: TitleType) {
		this.rows.update((rows) => {
			const titles = JSON.parse(localStorage.downloaded)[type];
			for (const title of titles) {
				title.released = new Date(title.released);
			}
			rows[0].titles = cacheTitles(titles);
			return rows;
		});

		this.rows.subscribe((rows) => {
			const downloaded = JSON.parse(localStorage.downloaded);
			localStorage.downloaded = JSON.stringify({
				...downloaded,
				[type]: rows[0].titles,
			});
		});

		Promise.all([
			(async () => {
				const trending = await getTrending(type);
				this.rows.update((rows) => {
					rows[1].titles = trending;
					return rows;
				});
			})(),
			(async () => {
				const topRated = await getTopRated(type);
				this.rows.update((rows) => {
					rows[2].titles = topRated;
					return rows;
				});
			})(),
			(async () => {
				const genres = await getGenres(type);
				for (const genre of genres) {
					const row = new Row(genre.genre);
					row.titles = genre.titles;
					this.rows.update((rows) => {
						rows.push(row);
						return rows;
					});
				}
			})(),
		]).then(() => {
			this.ready.set(true);
		});
	}
}

if (!localStorage.downloaded) {
	localStorage.downloaded = JSON.stringify({
		movie: [],
		tv: [],
	});
}

export default {
	movie: new State("movie"),
	tv: new State("tv"),
};
