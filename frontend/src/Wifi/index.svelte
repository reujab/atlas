<script lang="ts">
	import Cursor from "../Cursor.svelte";
	import ErrorBanner from "../ErrorBanner/index.svelte";
	import FaLock from "svelte-icons/fa/FaLock.svelte";
	import Header from "../Header/index.svelte";
	import Keyboard from "../Keyboard.svelte";
	import MdKeyboardReturn from "svelte-icons/md/MdKeyboardReturn.svelte";
	import childProcess from "child_process";
	import { Circle2 } from "svelte-loading-spinners";
	import { connected } from "../Init/state";
	import { error, log } from "../log";
	import { onDestroy } from "svelte";
	import { subscribe, unsubscribe } from "../gamepad";
	import { writable } from "svelte/store";

	interface Network {
		name: string;
		secure: boolean;
		strength: number;
		element: HTMLDivElement;
	}

	const password = writable("");
	let container: HTMLDivElement = null;
	let networks: Network[] = [];
	let networkIndex = 0;
	let selected = false;
	let timeout: NodeJS.Timeout;
	let connecting = false;

	function gamepadHandler(button: string): void {
		if (connecting) return;

		if (button === "B") {
			if (selected) {
				selected = false;
				timeout = setTimeout(updateNetworks, 1000);
			} else {
				history.back();
			}
			return;
		}

		if (!networks.length || selected) return;

		switch (button) {
			case "A":
				clearTimeout(timeout);
				selected = true;
				$password = "";
				if (!networks[networkIndex].secure) connect();
				break;
			case "up":
				if (networkIndex > 0) networkIndex--;
				break;
			case "down":
				if (networkIndex < networks.length - 1) networkIndex++;
				break;
		}

		scroll();
	}

	function scroll(): void {
		container?.scrollTo(0, networks[networkIndex].element?.offsetTop - 16);
	}

	function updateNetworks(): void {
		childProcess.exec("nmcli -t dev wifi", (err, stdout, stderr) => {
			if (err) {
				error("nmcli err", err);
			}

			if (stderr) {
				error("nmcli stderr", stderr);
			}

			if (selected) return;

			const oldName = networks[networkIndex]?.name;
			networks = stdout
				.trimEnd()
				.split("\n")
				.map((line) => {
					const parts = line.slice(25).split(":");
					return {
						name: parts[0],
						secure: Boolean(parts[6]),
						strength: Number(parts[4]),
						element: null,
					};
				})
				.filter((network) => network.name);
			const index = networks.findIndex((n) => n.name === oldName);
			if (index !== -1) networkIndex = index;
			if (networkIndex > networks.length - 1)
				networkIndex = networks.length - 1;
			setTimeout(scroll);
			timeout = setTimeout(updateNetworks, 10000);
		});
	}

	function connect(): void {
		const network = networks[networkIndex];
		if (network.secure && $password.length < 8) return;
		connecting = true;
		const nmcli = childProcess.spawn("nmcli", [
			"dev",
			"wifi",
			"connect",
			network.name,
			"password",
			$password,
		]);

		nmcli.on("exit", (code) => {
			log("nmcli exited with %O", code);
			if (code) {
				connecting = false;
				const codes: { [code: number]: string } = {
					3: "timed out",
					4: "wrong password",
					10: "access point does not exist",
				};
				error(
					"Failed to connect to network",
					codes[code] || `error code ${code}`
				);
				return;
			}

			function waitForConnection(): void {
				childProcess.exec("hostname -I", (err, stdout, stderr) => {
					if (err || stderr) {
						error("hostname err", err || stderr);
						setTimeout(waitForConnection, 500);
						return;
					}

					log("%O", stdout);

					$connected = stdout.trim().split(" ").length > 1;
					if ($connected) {
						location.hash = "#/home";
					} else {
						setTimeout(waitForConnection, 500);
					}
				});
			}
			waitForConnection();
		});
	}

	updateNetworks();

	subscribe(gamepadHandler);
	onDestroy(() => {
		unsubscribe(gamepadHandler);
	});
</script>

<ErrorBanner />

<div class="h-screen px-48 flex flex-col">
	<Header title="Wifi setup" back={$connected} />

	{#if networks.length}
		<div
			class="flex gap-8 flex-col text-2xl relative scroll-smooth overflow-scroll px-48 mt-4 py-4 items-center pb-[100vh]"
			bind:this={container}
		>
			{#each networks as network, i}
				<div
					class="network rounded-[3rem] bg-[#eee] white-shadow text-black text-4xl"
					class:active={i === networkIndex}
					class:inactive={selected && i !== networkIndex}
					bind:this={network.element}
				>
					<div class="px-16 py-4 flex h-[6.2rem] items-center">
						{network.name}
						<div class="grow" />
						{#if i === networkIndex && connecting}
							<div class="mr-8">
								<Circle2 />
							</div>
						{/if}
						{#if network.secure}
							<div class="h-full mr-8">
								<FaLock />
							</div>
						{/if}
						<svg
							xmlns="http://www.w3.org/2000/svg"
							viewBox="0 0 24 24"
							class="h-full"
						>
							{#if network.strength >= 75}
								<path
									d="M12,3C7.79,3 3.7,4.41 0.38,7C4.41,12.06 7.89,16.37 12,21.5C16.08,16.42 20.24,11.24 23.65,7C20.32,4.41 16.22,3 12,3Z"
								/>
							{:else if network.strength >= 67}
								<path
									d="M12,3C7.79,3 3.7,4.41 0.38,7C4.41,12.06 7.89,16.37 12,21.5C16.08,16.42 20.24,11.24 23.65,7C20.32,4.41 16.22,3 12,3M12,5C15.07,5 18.09,5.86 20.71,7.45L18.77,9.88C17.26,9 14.88,8 12,8C9,8 6.68,9 5.21,9.84L3.27,7.44C5.91,5.85 8.93,5 12,5Z"
								/>
							{:else if network.strength >= 33}
								<path
									d="M12,3C7.79,3 3.7,4.41 0.38,7C4.41,12.06 7.89,16.37 12,21.5C16.08,16.42 20.24,11.24 23.65,7C20.32,4.41 16.22,3 12,3M12,5C15.07,5 18.09,5.86 20.71,7.45L17.5,11.43C16.26,10.74 14.37,10 12,10C9.62,10 7.74,10.75 6.5,11.43L3.27,7.44C5.91,5.85 8.93,5 12,5Z"
								/>
							{:else}
								<path
									d="M12,3C7.79,3 3.7,4.41 0.38,7C4.41,12.06 7.89,16.37 12,21.5C16.08,16.42 20.24,11.24 23.65,7C20.32,4.41 16.22,3 12,3M12,5C15.07,5 18.09,5.86 20.71,7.45L15.61,13.81C14.5,13.28 13.25,13 12,13C10.75,13 9.5,13.28 8.39,13.8L3.27,7.44C5.91,5.85 8.93,5 12,5Z"
								/>
							{/if}
						</svg>
					</div>
					{#if i === networkIndex}
						<div
							class="password-field h-[25vh] overflow-hidden text-6xl px-16"
							class:active={selected &&
								networks[networkIndex].secure}
						>
							{"*".repeat(
								$password.length
							)}{#if !connecting}<Cursor />{/if}
						</div>
					{/if}
				</div>
			{/each}
		</div>
		<Keyboard
			active={selected && !connecting}
			text={password}
			submitIcon={MdKeyboardReturn}
			onSubmit={connect}
		/>
	{:else}
		<div class="flex justify-center items-center h-full">
			<Circle2 size={256} />
		</div>
	{/if}
</div>

<style>
	.network {
		transition: min-width 500ms, transform 500ms;
		min-width: 100%;
	}

	.network.inactive {
		transform: scaleX(0.4) translateY(-50%) rotate3d(1, 0, 0, 90deg);
	}

	.network.active {
		min-width: 105%;
	}

	.password-field {
		max-height: 0;
		transition: max-height 500ms;
	}

	.password-field.active {
		max-height: 5rem;
	}
</style>
