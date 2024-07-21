CREATE TABLE title_progress (
	type TEXT,
	id INT,

	season INT,
	episode INT,

	percent FLOAT,
	position FLOAT,

	ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	PRIMARY KEY (type, id, season, episode)
);
