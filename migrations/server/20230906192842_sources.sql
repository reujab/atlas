CREATE TABLE sources (
	magnet TEXT PRIMARY KEY,

	type type NOT NULL,
	id INT NOT NULL,

	seasons INT[],
	-- If `episode` is NULL and `type` is 'tv', this source contains every episode.
	episode INT,

	score FLOAT NOT NULL,
	defunct BOOLEAN NOT NULL DEFAULT FALSE,
	ts TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX sources_score ON sources (score DESC);

CREATE INDEX sources_ts ON sources (ts ASC);
