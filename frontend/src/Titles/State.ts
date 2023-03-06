import Row from "./Row";
import { getTrending, getTopRated, getTitlesWithGenre, sortedGenres, TitleType, cacheTitles } from "../db";
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

		getTrending(type).then((trending) => {
			this.rows.update((rows) => {
				rows[1].titles = trending;
				return rows;
			});
		});

		getTopRated(type).then((topRated) => {
			this.rows.update((rows) => {
				rows[2].titles = topRated;
				return rows;
			});
		});

		const interval = setInterval(() => {
			if (sortedGenres.length === 0) return;

			clearInterval(interval);

			let wg = 0;
			for (const genre of sortedGenres) {
				if (genre.name === "Family") continue;

				const row = new Row(genre.name);
				this.rows.update((rows) => {
					rows.push(row);
					return rows;
				});

				wg++;
				// eslint-disable-next-line no-loop-func
				getTitlesWithGenre(type, genre.id).then((titles) => {
					if (titles.length >= 6) {
						row.titles = titles;
					} else {
						this.rows.update((rows) => {
							rows.splice(rows.indexOf(row), 1);
							return rows;
						});
					}

					if (--wg === 0) this.ready.set(true);
				});
			}
		}, 100);
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
