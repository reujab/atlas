import Row from "./Row";
import { getTrending, getTopRated, getTitlesWithGenre, sortedGenres } from "../db";

class State {
	rows: Row[] = [new Row("Trending"), new Row("Top rated")]
	activeRow = 0

	constructor() {
		getTrending("movies").then((trending) => {
			this.rows[0].titles = trending;
		});

		getTopRated("movies").then((topRated) => {
			this.rows[1].titles = topRated;
		});

		for (const genre of sortedGenres) {
			const row = new Row(genre.name);
			this.rows.push(row);
			getTitlesWithGenre("movies", genre.id).then((movies) => {
				if (movies.length) {
					row.titles = movies;
				} else {
					this.rows.splice(this.rows.indexOf(row), 1);
				}
			});
		}
	}
}

export default new State();
