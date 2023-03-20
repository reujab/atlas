import { get } from ".";

export default async function getSeasons(id: string): Promise<any[]> {
	const seasons = [];

	for (let i = 0, keys = 20; keys === 20; i++) {
		const append = Array(20)
			.fill(null)
			.map((_, j) => `season/${i * 20 + j + 1}`)
			.join(",");
		// eslint-disable-next-line no-await-in-loop
		const json = await (await get(
			`https://api.themoviedb.org/3/tv/${id}?api_key=${process.env.TMDB_KEY}&append_to_response=${append}`
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
						date: episode.air_date,
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
		}
	}

	return seasons;
}
