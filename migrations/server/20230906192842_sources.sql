CREATE TABLE sources (
	type type,
	id INT,
	priority INT,

	seasons INT[],
	-- If `episode` is null and `type` is 'tv', this source contains every episode.
	episode INT,
	magnet TEXT NOT NULL,
	ts TIMESTAMP NOT NULL DEFAULT NOW(),

	PRIMARY KEY(type, id, priority)
);

CREATE INDEX sources_priority ON sources (priority DESC);

CREATE INDEX sources_ts ON sources (ts ASC);
