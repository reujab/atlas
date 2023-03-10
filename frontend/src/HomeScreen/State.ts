interface Weather {
	city: string;
	temp: string;
	icon: string;
	forecast: string;
}

class State {
	activeTile = 0;

	coords: null | number[] = null;

	weather: null | Weather = null;
}

export default new State();
