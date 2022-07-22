const GamepadListener = require("gamepad.js").GamepadListener;

const listener = new GamepadListener();
const handlers: ((button: string) => void)[] = [];

listener.start();

listener.on("gamepad:axis", (e: any) => {
	e = e.detail;
	console.log(e);
	if (e.value === 0 || e.stick !== 0) {
		return;
	}

	if (e.axis === 0 && e.value < 0) {
		dispatch("left");
	} else if (e.axis === 0 && e.value > 0) {
		dispatch("right");
	} else if (e.axis === 1 && e.value < 0) {
		dispatch("up");
	} else if (e.axis === 1 && e.value > 0) {
		dispatch("down");
	}
});

listener.on("gamepad:button", (e: any) => {
	if (e.detail.pressed) {
		console.log(e.detail.button)
		switch (e.detail.button) {
			case 0:
				dispatch("A");
				break;
			case 1:
				dispatch("B");
				break;
			case 2:
				dispatch("X");
				break;
			case 3:
				dispatch("Y");
				break;
			case 12:
				dispatch("up");
				break;
			case 13:
				dispatch("down");
				break;
			case 14:
				dispatch("left");
				break;
			case 15:
				dispatch("right");
				break;
		}
	}
});

function dispatch(e: string) {
	for (const cb of handlers) {
		cb(e);
	}
}

export function subscribe(cb: (button: string) => void) {
	handlers.push(cb);
};

export function unsubscribe(cb: (button: string) => void) {
	const index = handlers.indexOf(cb);
	if (index === -1) {
		throw new Error("cannot unsubscribe: handler not found");
	} else {
		handlers.splice(index, 1);
	}
}
