import { Title } from "../db";
import { get } from "..";

export interface Season {
	number: number;
	episodes: Episode[];
	activeEpisode: number;
	ele: null | HTMLDivElement;
	episodesEle: null | HTMLDivElement;
}

export interface Episode {
	number: number;
	date: Date;
	name: string;
	overview: string;
	runtime: number;
	still: string;
	ele: null | HTMLDivElement;
}

export default async function getSeasons(title: Title): Promise<Season[]> {
	const seasons: Season[] = [];
	const cache = [] as HTMLImageElement[];

	for (let i = 0, keys = 20; keys === 20; i++) {
		const append = Array(20)
			.fill(null)
			.map((_, j) => `season/${i * 20 + j + 1}`)
			.join(",");
		// eslint-disable-next-line no-await-in-loop
		const json = await (await get(
			`https://api.themoviedb.org/3/tv/${title.id}?api_key=${process.env.TMDB_KEY}&append_to_response=${append}`
		)).json();
		keys = Object.keys(json).filter((key) => key.startsWith("season/"))
			.length;

		for (let j = 0; j < 20; j++) {
			const season = json[`season/${i * 20 + j + 1}`];
			if (season?.episodes.length) {
				seasons.push({
					number: season.season_number,
					episodes: season.episodes.map((episode: any) => ({
						number: episode.episode_number,
						date: new Date(episode.air_date),
						name: episode.name,
						overview: episode.overview,
						runtime: episode.runtime,
						still: episode.still_path,
					})),
					activeEpisode: 0,
					ele: null,
					episodesEle: null,
				});
			}

			// preload first season stills
			if (i === 0 && j === 0) {
				for (const episode of seasons[0]?.episodes) {
					if (!episode.still) continue;
					const img = new Image();
					cache.push(img);
					img.src = `https://image.tmdb.org/t/p/w227_and_h127_bestv2${episode.still}`;
				}
			}
		}
	}

	return seasons;
}
