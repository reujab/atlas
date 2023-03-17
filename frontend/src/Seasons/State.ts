import { writable } from "svelte/store";
import { Season } from "../db";

class State {
	seasonIndex = 0;

	seasons = writable([] as Season[]);
}

export default new State();
