import { Title } from "../db";

export default class Row {
	name: string = null

	titles: Title[] = []

	activeCol = 0

	element: HTMLDivElement = null

	constructor(name: string) {
		this.name = name
	}
}
