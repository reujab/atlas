import { log } from "./log";
import { GamepadListener } from "gamepad.js";

interface Axis {
	interval?: NodeJS.Timeout
	lastButton?: "up" | "down" | "left" | "right" | null
}

const listener = new GamepadListener();
const handlers: ((button: string) => void)[] = [];
const axes: { [id: number]: Axis } = { 0: {}, 1: {} };
let buttonInterval: NodeJS.Timeout;

listener.start();

listener.on("gamepad:axis", ({ detail }: any) => {
	if (detail.stick !== 0) return;

	const axis = axes[detail.axis];

	if (Math.abs(detail.value) < 0.3) {
		clearInterval(axis.interval);
		axis.lastButton = null;
		return;
	}

	let button: null | "left" | "right" | "up" | "down" = null;
	if (detail.axis === 0 && detail.value < 0) button = "left";
	else if (detail.axis === 0 && detail.value > 0) button = "right";
	else if (detail.axis === 1 && detail.value < 0) button = "up";
	else if (detail.axis === 1 && detail.value > 0) button = "down";

	if (button === axis.lastButton) return;

	axis.lastButton = button;

	clearInterval(axis.interval);

	function dispatchButton(): void {
		if (button) dispatch(button);
	}

	dispatchButton();
	axis.interval = setInterval(dispatchButton, 300);
});

listener.on("gamepad:button", ({ detail }: any) => {
	const button = getButtonName(detail.button);

	function dispatchButton(): void {
		if (button) dispatch(button);
	}

	if (detail.pressed) {
		log("%O %O", button, detail.button);

		if (button === null) return;

		dispatchButton();
	}

	switch (button) {
		case "up":
		case "down":
		case "left":
		case "right":
			clearInterval(buttonInterval);
			if (detail.pressed) {
				buttonInterval = setInterval(dispatchButton, 300);
			}
	}
});

onkeydown = (e) => {
	switch (e.key) {
		case "ArrowLeft":
			dispatch("left");
			break;
		case "ArrowUp":
			dispatch("up");
			break;
		case "ArrowRight":
			dispatch("right");
			break;
		case "ArrowDown":
			dispatch("down");
			break;
		case "Enter":
			dispatch("A");
			break;
		case "Escape":
			dispatch("B");
			break;
		case "x":
			dispatch("X");
			break;
		case "y":
			dispatch("Y");
			break;
		default:
			return;
	}

	e.preventDefault();
};

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

function dispatch(e: string): void {
	for (const cb of handlers) cb(e);
}

export function subscribe(cb: (button: string) => void): void {
	handlers.push(cb);
}

export function unsubscribe(cb: (button: string) => void): void {
	const index = handlers.indexOf(cb);
	if (index === -1) {
		throw new Error("cannot unsubscribe: handler not found");
	} else {
		handlers.splice(index, 1);
	}
}
