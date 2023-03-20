import { getRows, TitleType, cacheTitles, Row } from "../db";
import { writable } from "svelte/store";
import { error } from "../log";

class State {
	rows = writable([{
		name: "My list",
		titles: [],
		activeCol: 0,
		element: null,
	}] as Row[]);

	activeRow = writable(1);

	constructor(type: TitleType) {
		this.rows.update((rows) => {
			const titles = JSON.parse(localStorage.myList)[type];
			rows[0].titles = cacheTitles(titles);
			if (rows[0].titles.length) this.activeRow.set(0);
			return rows;
		});

		this.rows.subscribe((rows) => {
			const myList = JSON.parse(localStorage.myList);
			localStorage.myList = JSON.stringify({
				...myList,
				[type]: rows[0].titles,
			});
		});

		getRows(type).then((rows) => {
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
