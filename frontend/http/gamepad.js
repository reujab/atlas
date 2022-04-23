import { GamepadListener } from "gamepad.js";

const listener = new GamepadListener();
const handlers = [];

listener.start();

listener.on("gamepad:button", (e) => {
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

function dispatch(e) {
	for (const cb of handlers) {
		cb(e);
	}
}

export function subscribe(cb) {
	handlers.push(cb);
};

export function unsubscribe(cb) {
	const index = handlers.indexOf(cb);
	if (index === -1) {
		throw new Error("cannot unsubscribe: handler not found");
	} else {
		handlers.splice(index, 1);
	}
}
