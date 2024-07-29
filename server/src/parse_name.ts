// export const episodeRegex = /\b(?:seasons?|s)[ .]*([\d s.,&-]+).*?(?:(?:episode|ep?)[ .]*(\d+))?|^(\d)(\d{2})\b/i;
export const episodeRegexes = [
	// Usual episode formatting: S01E01 or Season(s) 1-5.
	/\b(?:seasons?|s)[ .]*([\d s.,&-]+).*?(?:(?:episode|ep?)[ .]*(\d+))?/i,
	// Special case when name starts with three digits representing the season and episode. For
	// example, 202 would represent S02E02.
	/^(\d)(\d{2})\b/,
	// [1x01]
	/\[(\d+)x(\d+)\]/i,
];

export interface ParsedName {
	seasons: number[];
	episode: null | number;
}

export default function parseName(name: string): ParsedName {
	for (const regex of episodeRegexes) {
		const match = name.match(regex);
		if (!match) continue;

		const seasons = match[1]
			.replace(/[ .,&s-]+/gi, " ")
			.trim()
			.split(" ")
			.map(Number)
			// Filter out absurd numbers and duplicate seasons.
			.filter((s, i, arr) => s < 256 && arr.indexOf(s) == i);

		// If the name matches "S01-S08" or "Season 1-8", `seasons` will be `[1, 8]`.
		// Fill in the seasons in between.
		if (seasons.length === 2) {
			for (let i = seasons[0] + 1; i < seasons[1]; i++) {
				seasons.push(i);
			}
		}

		// FIXME: what if episode is 0?
		const episode = Number(match[2]) || null;
		return { seasons, episode };
	}

	return { seasons: [], episode: null };
}
