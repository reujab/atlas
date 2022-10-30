interface VPN {
	connected: null | boolean
	location: null | string
}

interface Weather {
	city: string
	temp: string
	icon: string
	forecast: string
}

class State {
	activeTile = 0;

	vpn: VPN = {
		connected: null,
		location: null,
	};

	weather: null | Weather = null;
}

export default new State();
