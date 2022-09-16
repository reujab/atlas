<script lang="ts">
	import Header from "../Header";
	import { subscribe, unsubscribe } from "../gamepad";
	import { onDestroy } from "svelte";
	import MdChevronLeft from "svelte-icons/md/MdChevronLeft.svelte";
	import MdSpaceBar from "svelte-icons/md/MdSpaceBar.svelte";
	import MdSearch from "svelte-icons/md/MdSearch.svelte";

	const keyboard = [
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "<"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L", "!"],
		["Z", "X", "C", "V", "B", "N", "M", " "],
	];
	let activeRow = 0;
	let activeCol = 4;
	let query = "";

	function gamepadHandler(button: string) {
		switch (button) {
			case "A":
				let char = keyboard[activeRow][activeCol];
				if (char === "<") {
					query = query.slice(0, -1);
				} else if (char === "!") {
					if (query) {
						location.href = `#/results/${query}`;
					}
				} else {
					if (query.length) {
						char = char.toLowerCase();
					}
					query += char;
				}
				break;
			case "left":
				if (activeCol > 0) {
					activeCol--;
				} else {
					activeCol = keyboard[activeRow].length - 1;
				}
				break;
			case "right":
				if (activeCol < keyboard[activeRow].length - 1) {
					activeCol++;
				} else {
					activeCol = 0;
				}
				break;
			case "up":
				if (activeRow > 0) {
					activeRow--;
					if (activeRow === 1) {
						activeCol++;
					}
				} else {
					activeRow = 2;
					activeCol--;
				}
				break;
			case "down":
				if (activeRow < 2) {
					activeRow++;
					if (activeRow === 2) {
						activeCol--;
					}
				} else {
					activeRow = 0;
					activeCol++;
				}
				break;
		}

		if (activeCol < 0) {
			activeCol = 0;
		} else if (activeCol > keyboard[activeRow].length - 1) {
			activeCol = keyboard[activeRow].length - 1;
		}
	}

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<div class="h-screen flex flex-col">
	<div class="px-48 grow">
		<Header title="Search" back />

		<div
			class="p-6 bg-white text-black rounded-full mt-4 text-6xl whitespace-pre overflow-hidden text-ellipsis"
		>
			{query}<span class="cursor relative top-[-0.35rem] right-[0.2rem]"
				>|</span
			>
		</div>
	</div>
	<div class="keyboard text-black text-center text-6xl">
		{#each keyboard as row, i}
			<div>
				{#each row as char, j}
					<span class:active={i === activeRow && j === activeCol}>
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
	.keyboard span {
		height: 7rem;
		width: 7rem;
		border: 1px solid gray;
		margin: 20px 0;
		background: white;
		border-radius: 2rem;
		transition: transform 500ms;
		display: flex;
		justify-content: center;
		align-items: center;
		padding: 1.5rem;
	}

	.keyboard > div {
		gap: 2rem;
		display: flex;
		justify-content: center;
	}

	.active {
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
</style>
