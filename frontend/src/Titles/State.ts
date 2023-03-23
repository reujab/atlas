import { getRows, TitleType, cacheTitles, Row } from "../db";
import { writable } from "svelte/store";
import { error } from "../log";

class State {
	type: TitleType;

	rows = writable([{
		name: "My list",
		titles: [],
		activeCol: 0,
		element: null,
	}] as Row[]);

	activeRow = writable(1);

	constructor(type: TitleType) {
		this.type = type;
	}

	init(): void {
		this.rows.update((rows) => {
			const titles = JSON.parse(localStorage.myList)[this.type];
			rows[0].titles = cacheTitles(titles);
			if (rows[0].titles.length) this.activeRow.set(0);
			return rows;
		});

		this.rows.subscribe((rows) => {
			const myList = JSON.parse(localStorage.myList);
			localStorage.myList = JSON.stringify({
				...myList,
				[this.type]: rows[0].titles,
			});
		});

		getRows(this.type).then((rows) => {
			this.rows.update((myList) => [
				...myList,
				...rows,
			]);
		}).catch((err) => {
			error("Error getting rows", err);
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
