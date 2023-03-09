export const episodeRegex = /\b(?:seasons?|s)[ .]*([\d s.,&-]+).*?(?:(?:episode|ep?)[ .]*(\d+))?/i;

export interface ParsedName {
	seasons: number[];
	episode: null | number;
}

export default function parseName(name: string): ParsedName {
	const match = name.match(episodeRegex);
	if (!match) return { seasons: [], episode: null };

	const seasons = match[1]
		.replace(/[ .,&s-]+/gi, " ")
		.trim()
		.split(" ")
		.map(Number)
		.filter((s) => s < 256);
	if (seasons.length === 2) {
		for (let i = seasons[0] + 1; i < seasons[1]; i++) {
			seasons.push(i);
		}
	}
	const episode = Number(match[2]) || null;
	return { seasons, episode };
}
