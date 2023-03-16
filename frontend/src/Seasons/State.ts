import { Season } from "../db";

class State {
	seasonIndex = 0;

	seasons: Season[] = [];
}

export default new State();
