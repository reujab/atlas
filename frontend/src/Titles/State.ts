import Row from "./Row";
import { getTrending, getTopRated, getTitlesWithGenre, sortedGenres } from "../db";

class State {
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
			for (const genre of sortedGenres) {
				const row = new Row(genre.name);
				this.rows.push(row);
				getTitlesWithGenre(type, genre.id).then((titles) => {
					if (titles.length) {
						row.titles = titles;
					} else {
						this.rows.splice(this.rows.indexOf(row), 1);
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
