export const episodeRegex = /\b(?:seasons?|s)[ .]*([\d s.,&-]+).*?(?:(?:episode|ep?)[ .]*(\d+))?|^(\d)(\d{2})\b/i;

export interface ParsedName {
	seasons: number[];
	episode: null | number;
}

export default function parseName(name: string): ParsedName {
	const match = name.match(episodeRegex);
	if (!match) return { seasons: [], episode: null };

	// Special case when name starts with three digits representing the season and episode. For
	// example, 202 would represent S02E02
	if (match[3] && match[4]) {
		return { seasons: [Number(match[3])], episode: Number(match[4]) };
	}

	const seasons = match[1]
		.replace(/[ .,&s-]+/gi, " ")
		.trim()
		.split(" ")
		.map(Number)
		// Filter out absurd numbers and duplicate seasons
		.filter((s, i, arr) => s < 256 && arr.indexOf(s) == i);

	// If the name matches "S01-S08" or "Season 1-8", `seasons` will be `[1, 8]`.
	// Fill in the seasons in between.
	if (seasons.length === 2) {
		for (let i = seasons[0] + 1; i < seasons[1]; i++) {
			seasons.push(i);
		}
	}

	const episode = Number(match[2]) || null;
	return { seasons, episode };
}
