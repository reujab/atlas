<script lang="ts">
	export let active: boolean,
		text: Writable<string>,
		submitIcon: any,
		// eslint-disable-next-line
		onExit = (_button: string): boolean => false,
		// eslint-disable-next-line func-style
		onSubmit = (): void => {};

	import GamepadButton from "./GamepadButton.svelte";
	import MdArrowUpward from "svelte-icons/md/MdArrowUpward.svelte";
	import MdChevronLeft from "svelte-icons/md/MdChevronLeft.svelte";
	import MdSpaceBar from "svelte-icons/md/MdSpaceBar.svelte";
	import { writable, Writable } from "svelte/store";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "./gamepad";

	enum ShiftMode {
		Disabled,
		Shift,
		Caps,
	}

	const keyboard = [
		[
			["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", backspace],
			[shift, "A", "S", "D", "F", "G", "H", "J", "K", "L", onSubmit],
			[swap, "Z", "X", "C", "V", "B", "N", "M", " "],
		],
		[
			["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", backspace],
			["_", "-", "/", ":", ";", "+", "=", "$", "&", "@", "*"],
			[swap, "$", ".", ",", "?", "!", "^", "%", "#"],
		],
	];
	let page = 0;
	let activeRow = 1;
	let activeCol = 4;
	let depressed: Writable<null | string | (() => void)> = writable(null);
	let depressedTimeout: NodeJS.Timeout = null;
	let shiftMode = ShiftMode.Disabled;
	let lastShift = 0;

	function gamepadHandler(button: string): void {
		if (!active) return;

		switch (button) {
			case "A":
				let char = keyboard[page][activeRow][activeCol];
				$depressed = char;
				if (typeof char === "function") {
					char();
				} else {
					if (shiftMode === ShiftMode.Disabled) {
						char = char.toLowerCase();
					}
					$text += char;
					if (shiftMode === ShiftMode.Shift) {
						shiftMode = ShiftMode.Disabled;
					}
				}
				break;
			case "X":
				$text = $text.slice(0, -1);
				$depressed = backspace;
				break;
			case "Y":
				$text += " ";
				$depressed = " ";
				break;
			case "up":
				if (activeRow === 0) {
					if (!onExit(button)) {
						activeRow = 2;
						activeCol--;
					}
				} else {
					activeRow--;
					if (activeRow === 1) activeCol++;
				}
				break;
			case "down":
				if (activeRow === 2) {
					if (!onExit(button)) {
						activeRow = 0;
						activeCol++;
					}
				} else {
					activeRow++;
					if (activeRow === 2) activeCol--;
				}
				break;
			case "left":
				if (activeCol === 0) {
					if (!onExit(button)) {
						activeCol = keyboard[page][activeRow].length - 1;
					}
				} else {
					activeCol--;
				}
				break;
			case "right":
				if (activeCol === keyboard[page][activeRow].length - 1) {
					if (!onExit(button)) {
						activeCol = 0;
					}
				} else {
					activeCol++;
				}
				break;
		}

		if (activeCol < 0) {
			activeCol = 0;
		} else if (activeCol > keyboard[page][activeRow].length - 1) {
			activeCol = keyboard[page][activeRow].length - 1;
		}
	}

	function backspace(): void {
		$text = $text.slice(0, -1);
	}

	function shift(): void {
		if (Date.now() - lastShift < 500 && shiftMode === ShiftMode.Shift) {
			shiftMode = ShiftMode.Caps;
		} else if (shiftMode === ShiftMode.Disabled) {
			shiftMode = ShiftMode.Shift;
		} else {
			shiftMode = ShiftMode.Disabled;
		}
		lastShift = Date.now();
	}

	function swap(): void {
		page = Number(!page);
	}

	const depressedUnsub = depressed.subscribe(() => {
		clearTimeout(depressedTimeout);
		depressedTimeout = setTimeout(() => {
			$depressed = null;
		}, 120);
	});

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
		depressedUnsub();
	});
</script>

<div
	class="keyboard text-black text-center text-6xl absolute bottom-0 left-0 right-0"
	class:active
>
	{#each keyboard[page] as row, i}
		<div>
			{#each row as char, j}
				<div
					class="char relative white-shadow"
					class:active={i === activeRow && j === activeCol}
					class:depressed={char === $depressed}
					class:shift={char === shift &&
						shiftMode === ShiftMode.Shift}
					class:caps={char === shift && shiftMode === ShiftMode.Caps}
				>
					{#if char === backspace}
						<GamepadButton button="X" position={20} />
						<MdChevronLeft />
					{:else if char === onSubmit}
						<svelte:component this={submitIcon} />
					{:else if char === " "}
						<GamepadButton button="Y" position={20} />
						<div class="mb-[-2rem]">
							<MdSpaceBar />
						</div>
					{:else if char === shift}
						<MdArrowUpward />
					{:else if char === swap}
						<span class="text-4xl">
							{#if page === 0}
								123
							{:else}
								ABC
							{/if}
						</span>
					{:else}
						{char}
					{/if}
				</div>
			{/each}
		</div>
	{/each}
</div>

<style>
	.keyboard {
		transition: transform 1s;
		transform: translateY(120%);
	}

	.keyboard.active {
		transform: none;
	}

	.keyboard > div {
		margin: 2rem 0;
		gap: 2rem;
		display: flex;
		justify-content: center;
	}

	.char {
		height: 7rem;
		width: 7rem;
		background: white;
		border-radius: 2rem;
		transition: transform 500ms, border 300ms, color 300ms;
		display: flex;
		justify-content: center;
		align-items: center;
		padding: 1.5rem;
	}

	.char.active {
		transform: scale(1.2);
	}

	.char.depressed {
		transform: scale(0.8);
	}

	.char.shift {
		border: 0.4rem solid #7899d4;
		color: #7899d4;
	}

	.char.caps {
		border: 0.4rem solid #cc8b8c;
		color: #cc8b8c;
	}
</style>
