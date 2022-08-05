import { log } from "./log"

const GamepadListener = require("gamepad.js").GamepadListener;

const listener = new GamepadListener();
const handlers: ((button: string) => void)[] = [];
let timeout: NodeJS.Timeout;

listener.start();

listener.on("gamepad:axis", (e: any) => {
	clearTimeout(timeout);
	e = e.detail;
	log("%O", e);
	if (e.value === 0 || e.stick !== 0) {
		return;
	}

	let button: string;
	if (e.axis === 0 && e.value < 0) {
		button = "left";
	} else if (e.axis === 0 && e.value > 0) {
		button = "right";
	} else if (e.axis === 1 && e.value < 0) {
		button = "up";
	} else if (e.axis === 1 && e.value > 0) {
		button = "down";
	} else {
		log("shouldn't happen");
		return;
	}

	function localDispatch() {
		dispatch(button);
		timeout = setTimeout(localDispatch, 250);
	}

	localDispatch();
});

listener.on("gamepad:button", (e: any) => {
	if (e.detail.pressed) {
		const button = getButtonName(e.detail.button)
		log("%O %O", button, e.detail.button);

		if (button === null) {
			return;
		}

		dispatch(button);
	}
});

function getButtonName(id: number): string | null {
	switch (id) {
		case 0:
			return "A";
		case 1:
			return "B";
		case 2:
			return "X";
		case 3:
			return "Y";
		case 12:
			return "up";
		case 13:
			return "down";
		case 14:
			return "left";
		case 15:
			return "right";
		default:
			return null;
	}
}

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
