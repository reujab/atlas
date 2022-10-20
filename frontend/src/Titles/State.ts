import Row from "./Row";
import { getTrending, getTopRated, getTitlesWithGenre, sortedGenres } from "../db";

class State {
	ready = false
	rows: Row[] = [new Row("Trending"), new Row("Top rated")]
	activeRow = 0

	constructor(type: "movie" | "tv") {
		getTrending(type).then((trending) => {
			this.rows[0].titles = trending;
		});

		getTopRated(type).then((topRated) => {
			this.rows[1].titles = topRated;
		});

		const interval = setInterval(() => {
			if (sortedGenres.length === 0) {
				return;
			}

			clearInterval(interval);

			let wg = 0;
			for (const genre of sortedGenres) {
				if (["Kids", "News", "Talk", "Family"].includes(genre.name)) {
					continue;
				}

				const row = new Row(genre.name);
				this.rows.push(row);

				wg++;
				getTitlesWithGenre(type, genre.id).then((titles) => {
					if (titles.length >= 6) {
						row.titles = titles;

					} else {
						this.rows.splice(this.rows.indexOf(row), 1);
					}

					if (--wg === 0) {
						this.ready = true;
					}
				});
			}
		}, 100);
	}
}

export default {
	movie: new State("movie"),
	tv: new State("tv"),
};
