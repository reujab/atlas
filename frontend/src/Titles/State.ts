import Row from "./Row";
import { getTrending, getTopRated, getGenres, TitleType, cacheTitles } from "../db";
import { writable } from "svelte/store";

class State {
	ready = writable(false);

	rows = writable([
		new Row("My list"),
		new Row("Trending"),
		new Row("Top rated"),
	]);

	activeRow = 0;

	constructor(type: TitleType) {
		this.rows.update((rows) => {
			const titles = JSON.parse(localStorage.myList)[type];
			for (const title of titles) {
				title.released = new Date(title.released);
			}
			rows[0].titles = cacheTitles(titles);
			return rows;
		});

		this.rows.subscribe((rows) => {
			const myList = JSON.parse(localStorage.myList);
			localStorage.myList = JSON.stringify({
				...myList,
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

if (!localStorage.myList) {
	localStorage.myList = JSON.stringify({
		movie: [],
		tv: [],
	});
}

export default {
	movie: new State("movie"),
	tv: new State("tv"),
};
