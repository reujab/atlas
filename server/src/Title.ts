export default interface Title {
	id: number;
	type: "movie" | "tv";

	ts: Date;
	title: string;
	genres: number[];
	language?: string;
	popularity: number;
	rating?: string;
	released?: Date;
	runtime?: number;
	score?: number;
	votes?: number;
	trailer?: string;
	overview: string;
	poster?: string;
}
