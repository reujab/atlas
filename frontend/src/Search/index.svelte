<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import GamepadButton from "../GamepadButton/index.svelte";
	import Header from "../Header/index.svelte";
	import MdChevronLeft from "svelte-icons/md/MdChevronLeft.svelte";
	import MdSearch from "svelte-icons/md/MdSearch.svelte";
	import MdSpaceBar from "svelte-icons/md/MdSpaceBar.svelte";
	import seasonsState from "../Seasons/State";
	import state from "./State";
	import { getAutocomplete, Title } from "../db";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";

	const autocompleteCache: { [query: string]: Title[] } = {};
	const keyboard = [
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "<"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L", "\n"],
		["Z", "X", "C", "V", "B", "N", "M", " "],
	];
	const seasons = seasonsState.seasons;
	let activeRow = 0;
	let activeCol = 4;
	let autocomplete: Title[] = [];

	function gamepadHandler(button: string): void {
		switch (button) {
			case "A":
				seasonsState.seasonIndex = 0;
				$seasons = [];

				if (activeRow >= 0) {
					let char = keyboard[activeRow][activeCol];
					if (char === "<") {
						state.query = state.query.slice(0, -1);
						update();
					} else if (char === "\n") {
						// if (state.query)
						// 	location.href = `#/results/${state.query}`;
					} else {
						if (state.query.length) char = char.toLowerCase();
						state.query += char;
						if (state.query.length === 1) autocomplete = [];
						update();
					}
				} else {
					const title = autocomplete[activeRow + autocomplete.length];
					location.href = `#/${title.type}/${title.id}`;
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
					if (activeRow === 1) activeCol++;
				} else if (
					state.query &&
					autocomplete.length &&
					activeRow > -autocomplete.length
				) {
					activeRow--;
				} else {
					activeRow = 2;
					activeCol--;
				}
				break;
			case "down":
				if (activeRow < 2) {
					activeRow++;
					if (activeRow === 2) activeCol--;
				} else if (state.query && autocomplete.length) {
					activeRow = -autocomplete.length;
				} else {
					activeRow = 0;
					activeCol++;
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

	async function update(): Promise<void> {
		const { query } = state;

		if (!query) return;

		if (autocompleteCache[query]) {
			autocomplete = autocompleteCache[query];
			return;
		}

		// remove old search results
		const blacklist = new Set();
		for (let i = 1; i < query.length - 1; i++) {
			const titles = autocompleteCache[query.slice(0, i)];
			if (titles) {
				for (const title of titles) {
					blacklist.add(title.id);
				}
			}
		}

		const res = await getAutocomplete(query, [...blacklist] as number[]);
		if (res) {
			autocomplete = res;
			autocompleteCache[query] = res;
		}
	}

	update();
	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<ErrorBanner />

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
						{@html title.posterImg.outerHTML}
					</div>
					<span class="self-center grow whitespace-normal">
						{title.title}
					</span>
					<span class="self-center text-slate-600">
						{title.released?.getFullYear() || ""}
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
					<div
						class="char relative white-shadow"
						class:active={i === activeRow && j === activeCol}
					>
						{#if char === "<"}
							<GamepadButton button="X" position={20} />
							<MdChevronLeft />
						{:else if char === "\n"}
							<MdSearch />
						{:else if char === " "}
							<GamepadButton button="Y" position={20} />
							<div class="mb-[-2rem]">
								<MdSpaceBar />
							</div>
						{:else}
							{char}
						{/if}
					</div>
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

	.char {
		height: 7rem;
		width: 7rem;
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
