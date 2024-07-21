CREATE TABLE title_progress (
	type TEXT NOT NULL,
	id INT NOT NULL,

	-- These columns cannot default to NULL because of how sqlite treats NULL primary keys.
	season INT NOT NULL DEFAULT -1,
	episode INT NOT NULL DEFAULT -1,

	percent FLOAT NOT NULL,
	position FLOAT,

	ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	PRIMARY KEY (type, id, season, episode)
);
