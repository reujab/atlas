<script lang="ts">
	import Cursor from "../Cursor.svelte";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import Header from "../Header/index.svelte";
	import Keyboard from "../Keyboard.svelte";
	import seasonsState from "../Seasons/State";
	import { getAutocomplete, Title } from "../db";
	import { onDestroy } from "svelte";
	import { query } from "./state";
	import { subscribe, unsubscribe } from "../gamepad";
	import MdSearch from "svelte-icons/md/MdSearch.svelte";

	const autocompleteCache: { [query: string]: Title[] } = {};
	const seasons = seasonsState.seasons;
	let activeTitle = 0;
	let autocomplete: Title[] = [];
	let showKeyboard = true;
	$: visibleResultsNum = $query
		? Math.min(showKeyboard ? 2 : Infinity, autocomplete.length)
		: 0;

	function gamepadHandler(button: string): void {
		if (button === "B") {
			if (showKeyboard) {
				setTimeout(() => {
					$query = "";
				});
				history.back();
			} else {
				showKeyboard = true;
			}
			return;
		}

		if (showKeyboard) return;

		switch (button) {
			case "A":
				if (!showKeyboard) {
					seasonsState.seasonIndex = 0;
					$seasons = [];
					const title = autocomplete[activeTitle];
					location.href = `#/${title.type}/${title.id}`;
				}
				break;
			case "up":
				if (activeTitle !== 0) {
					activeTitle = Math.max(0, activeTitle - 1);
				}
				break;
			case "down":
				if (activeTitle === visibleResultsNum - 1) {
					showKeyboard = true;
				} else {
					activeTitle++;
				}
				break;
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
			const titles = autocompleteCache[$query.slice(0, i)].slice(0, 2);
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

	const queryUnsubscribe = query.subscribe((q) => {
		if (q.length === 1) autocomplete = [];
		update();
	});

	function onKeyboardSubmit(): void {
		showKeyboard = false;
	}

	function onKeyboardExit(button: string): boolean {
		if (!visibleResultsNum || button === "down") {
			return false;
		}

		showKeyboard = false;
		activeTitle = visibleResultsNum - 1;
		return true;
	}

	update();
	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
		queryUnsubscribe();
	});
</script>

<ErrorBanner />

<div class="h-screen flex flex-col">
	<div class="px-48">
		<Header title="Search" back />

		<div
			class="search p-4 pb-0 bg-white text-black rounded-[2rem] mt-4 text-6xl whitespace-pre text-ellipsis white-shadow"
		>
			{$query}<Cursor />
			<div
				class="results overflow-hidden mt-4"
				style="max-height: {visibleResultsNum * (160 + 16)}px"
			>
				{#each autocomplete as title, i}
					<div
						class="title text-6xl h-40 flex gap-4 mb-4 rounded-[2rem] drop-shadow"
						class:active={!showKeyboard && activeTitle === i}
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
	<Keyboard
		active={showKeyboard}
		text={query}
		submitIcon={MdSearch}
		onSubmit={onKeyboardSubmit}
		onExit={onKeyboardExit}
	/>
</div>

<style>
	.results {
		transition: 1s max-height;
	}

	.title {
		transition: 500ms margin-left;
	}

	.title.active {
		margin-left: 3rem;
	}
</style>
