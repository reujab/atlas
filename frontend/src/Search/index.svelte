<script lang="ts">
	import Header from "../Header/index.svelte";
	import MdChevronLeft from "svelte-icons/md/MdChevronLeft.svelte";
	import MdSearch from "svelte-icons/md/MdSearch.svelte";
	import MdSpaceBar from "svelte-icons/md/MdSpaceBar.svelte";
	import state from "./State";
	import { getAutocomplete, Title } from "../db";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	const keyboard = [
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "<"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L", "!"],
		["Z", "X", "C", "V", "B", "N", "M", " "],
	];
	let activeRow = 0;
	let activeCol = 4;
	let autocomplete: Title[] = [];

	function gamepadHandler(button: string) {
		switch (button) {
			case "A":
				if (activeRow >= 0) {
					let char = keyboard[activeRow][activeCol];
					if (char === "<") {
						state.query = state.query.slice(0, -1);
						update();
					} else if (char === "!") {
						if (state.query) {
							location.href = `#/results/${state.query}`;
						}
					} else {
						if (state.query.length) {
							char = char.toLowerCase();
						}
						state.query += char;
						if (state.query.length === 1) {
							autocomplete = [];
						}
						update();
					}
				} else {
					location.href = `#/movies/details/${
						autocomplete[activeRow + autocomplete.length].id
					}`;
				}
				break;
			case "B":
				setTimeout(() => {
					state.query = "";
				});
				history.back();
				break;
			case "X":
				state.query = state.query.slice(0, -1);
				update();
				break;
			case "Y":
				state.query += " ";
				update();
				break;
			case "left":
				if (activeRow >= 0) {
					if (activeCol > 0) {
						activeCol--;
					} else {
						activeCol = keyboard[activeRow].length - 1;
					}
				}
				break;
			case "right":
				if (activeRow >= 0) {
					if (activeCol < keyboard[activeRow].length - 1) {
						activeCol++;
					} else {
						activeCol = 0;
					}
				}
				break;
			case "up":
				if (activeRow > 0) {
					activeRow--;
					if (activeRow === 1) {
						activeCol++;
					}
				} else {
					if (
						state.query &&
						autocomplete.length &&
						activeRow > -autocomplete.length
					) {
						activeRow--;
					} else {
						activeRow = 2;
						activeCol--;
					}
				}
				break;
			case "down":
				if (activeRow < 2) {
					activeRow++;
					if (activeRow === 2) {
						activeCol--;
					}
				} else {
					if (state.query && autocomplete.length) {
						activeRow = -autocomplete.length;
					} else {
						activeRow = 0;
						activeCol++;
					}
				}
				break;
		}

		if (activeRow >= 0) {
			if (activeCol < 0) {
				activeCol = 0;
			} else if (activeCol > keyboard[activeRow].length - 1) {
				activeCol = keyboard[activeRow].length - 1;
			}
		}
	}

	async function update() {
		if (state.query) {
			autocomplete = (await getAutocomplete(state.query)) || autocomplete;
		}
	}

	update();
	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen flex flex-col">
	<div class="px-48 grow">
		<Header title="Search" back />

		<div
			class="search p-4 bg-white text-black rounded-[2rem] mt-4 text-6xl whitespace-pre overflow-hidden text-ellipsis white-shadow max-h-[92px]"
			class:extended-1={state.query && autocomplete.length === 1}
			class:extended-2={state.query && autocomplete.length === 2}
		>
			{state.query}<span
				class="cursor relative top-[-0.35rem] right-[0.2rem]">|</span
			>
			{#each autocomplete as title, i}
				<div
					class="title text-6xl h-40 flex gap-4 mt-4 rounded-[2rem] drop-shadow"
					class:active={activeRow + autocomplete.length === i}
				>
					<div
						class="flex justify-center rounded-[2rem] overflow-hidden shrink-0"
					>
						{@html title.poster.outerHTML}
					</div>
					<span class="self-center grow whitespace-normal">
						{title.title}
					</span>
					<span class="self-center text-slate-600">
						{title.released?.slice(0, 4) || ""}
					</span>
				</div>
			{/each}
			<div class="h-72" />
		</div>
	</div>
	<div class="keyboard text-black text-center text-6xl">
		{#each keyboard as row, i}
			<div>
				{#each row as char, j}
					<span
						class="char"
						class:active={i === activeRow && j === activeCol}
					>
						{#if char === "<"}
							<MdChevronLeft />
						{:else if char === "!"}
							<MdSearch />
						{:else if char === " "}
							<div class="mb-[-2rem]">
								<MdSpaceBar />
							</div>
						{:else}
							{char}
						{/if}
					</span>
				{/each}
			</div>
		{/each}
	</div>
</div>

<style>
	.keyboard > div {
		margin: 2rem 0;
		gap: 2rem;
		display: flex;
		justify-content: center;
	}

	.keyboard span {
		height: 7rem;
		width: 7rem;
		border: 1px solid gray;
		background: white;
		border-radius: 2rem;
		transition: transform 500ms;
		display: flex;
		justify-content: center;
		align-items: center;
		padding: 1.5rem;
	}

	.char.active {
		transform: scale(1.2);
	}

	.cursor {
		animation: 1s infinite normal blink;
	}

	@keyframes blink {
		from {
			opacity: 0;
		}

		10% {
			opacity: 0;
		}

		30% {
			opacity: 1;
		}

		70% {
			opacity: 1;
		}

		90% {
			opacity: 0;
		}

		to {
			opacity: 0;
		}
	}

	.search {
		transition: 1s max-height;
	}

	.search.extended-1 {
		max-height: 268px;
	}

	.search.extended-2 {
		max-height: 444px;
	}

	.title {
		transition: 500ms margin-left;
	}

	.title.active {
		margin-left: 3rem;
	}
</style>