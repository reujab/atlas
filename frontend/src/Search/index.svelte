<script lang="ts">
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import GamepadButton from "../GamepadButton/index.svelte";
	import Header from "../Header/index.svelte";
	import MdChevronLeft from "svelte-icons/md/MdChevronLeft.svelte";
	import MdSearch from "svelte-icons/md/MdSearch.svelte";
	import MdSpaceBar from "svelte-icons/md/MdSpaceBar.svelte";
	import seasonsState from "../Seasons/State";
	import { getAutocomplete, Title } from "../db";
	import { onDestroy } from "svelte";
	import { query } from "./state";
	import { subscribe, unsubscribe } from "../gamepad";

	const autocompleteCache: { [query: string]: Title[] } = {};
	const keyboard = [
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "<"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L", "\n"],
		["Z", "X", "C", "V", "B", "N", "M", " "],
	];
	const seasons = seasonsState.seasons;
	let activeTitle = 0;
	let activeRow = 0;
	let activeCol = 4;
	let autocomplete: Title[] = [];
	let showKeyboard = true;
	$: visibleResultsNum = $query
		? Math.min(showKeyboard ? 2 : Infinity, autocomplete.length)
		: 0;

	function gamepadHandler(button: string): void {
		switch (button) {
			case "A":
				seasonsState.seasonIndex = 0;
				$seasons = [];

				if (activeRow >= 0) {
					let char = keyboard[activeRow][activeCol];
					if (char === "<") {
						$query = $query.slice(0, -1);
						update();
					} else if (char === "\n") {
						showKeyboard = false;
						activeRow = -1;
					} else {
						if ($query.length) char = char.toLowerCase();
						$query += char;
						if ($query.length === 1) autocomplete = [];
						update();
					}
				} else {
					const title = autocomplete[activeTitle];
					location.href = `#/${title.type}/${title.id}`;
				}
				break;
			case "B":
				if (showKeyboard) {
					setTimeout(() => {
						$query = "";
					});
					history.back();
				} else {
					showKeyboard = true;
					activeRow = 1;
				}
				break;
			case "X":
				if (activeRow !== -1) {
					$query = $query.slice(0, -1);
					update();
				}
				break;
			case "Y":
				if (activeRow !== -1) {
					$query += " ";
					update();
				}
				break;
			case "left":
				if (activeRow !== -1) {
					if (activeCol > 0) {
						activeCol--;
					} else {
						activeCol = keyboard[activeRow].length - 1;
					}
				}
				break;
			case "right":
				if (activeRow !== -1) {
					if (activeCol < keyboard[activeRow].length - 1) {
						activeCol++;
					} else {
						activeCol = 0;
					}
				}
				break;
			case "up":
				if (activeRow === -1) {
					if (activeTitle === 0) {
						if (showKeyboard) {
							activeRow = 2;
							activeCol--;
						} else {
							activeTitle = visibleResultsNum - 1;
						}
					} else {
						activeTitle = Math.max(0, activeTitle - 1);
					}
				} else if (activeRow === 0) {
					if (visibleResultsNum) {
						activeRow = -1;
						activeTitle = visibleResultsNum - 1;
					} else {
						activeRow = 2;
						activeCol--;
					}
				} else {
					activeRow--;
					if (activeRow === 1) activeCol++;
				}
				break;
			case "down":
				if (activeRow === -1) {
					if (activeTitle === visibleResultsNum - 1) {
						if (showKeyboard) {
							activeRow = 0;
						} else {
							activeTitle = 0;
						}
					} else {
						activeTitle++;
					}
				} else if (activeRow === 2) {
					if (visibleResultsNum) {
						activeRow = -1;
						activeTitle = 0;
					} else {
						activeRow = 0;
						activeCol++;
					}
				} else {
					activeRow++;
					if (activeRow === 2) activeCol--;
				}
				break;
		}

		if (activeRow !== -1) {
			if (activeCol < 0) {
				activeCol = 0;
			} else if (activeCol > keyboard[activeRow].length - 1) {
				activeCol = keyboard[activeRow].length - 1;
			}
		}
	}

	async function update(): Promise<void> {
		if (!$query) return;

		if (autocompleteCache[$query]) {
			autocomplete = autocompleteCache[$query];
			return;
		}

		// remove old search results
		const blacklist = new Set();
		for (let i = 1; i < $query.length - 1; i++) {
			const titles = autocompleteCache[$query.slice(0, i)];
			if (titles) {
				for (const title of titles) {
					blacklist.add(title.id);
				}
			}
		}

		const res = await getAutocomplete($query, [...blacklist] as number[]);
		if (res) {
			autocomplete = res;
			autocompleteCache[$query] = res;
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
	<div class="px-48">
		<Header title="Search" back />

		<div
			class="search p-4 pb-0 bg-white text-black rounded-[2rem] mt-4 text-6xl whitespace-pre text-ellipsis white-shadow"
		>
			{$query}<span class="cursor relative top-[-0.35rem] right-[0.2rem]"
				>|</span
			>
			<div
				class="results overflow-hidden mt-4"
				style="max-height: {visibleResultsNum * (160 + 16)}px"
			>
				{#each autocomplete as title, i}
					<div
						class="title text-6xl h-40 flex gap-4 mb-4 rounded-[2rem] drop-shadow"
						class:active={activeRow === -1 && activeTitle === i}
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
	</div>
	<div
		class="keyboard text-black text-center text-6xl absolute bottom-0 left-0 right-0"
		class:active={showKeyboard}
	>
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
	.results {
		transition: 1s max-height;
	}

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

	.title {
		transition: 500ms margin-left;
	}

	.title.active {
		margin-left: 3rem;
	}
</style>
