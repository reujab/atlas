import { Season } from "./getSeasons";

class State {
	seasonIndex = 0;

	seasons: Season[] = [];
}

export default new State();
