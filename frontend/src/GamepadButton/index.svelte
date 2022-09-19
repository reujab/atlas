<script lang="ts">
	export let button: "A" | "B" | "X" | "Y";
	export let position = -12;
</script>

<div
	style="top: {position}px; left: {position}px;"
	class="w-[24px] h-[24px] bg-red-500 text-white absolute rounded-full drop-shadow text-lg flex items-center justify-center"
	class:bg-green-600={button === "A"}
	class:bg-red-500={button === "B"}
	class:bg-blue-500={button === "X"}
	class:bg-yellow-600={button === "Y"}
	class:pb-[2px]={button === "B"}
>
	{button}
</div>
