import { Title } from "../db";

export default class Row {
	name = "";

	titles: Title[] = [];

	activeCol = 0;

	element: null | HTMLDivElement = null;

	constructor(name: string) {
		this.name = name;
	}
}
