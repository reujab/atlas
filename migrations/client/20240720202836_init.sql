CREATE TABLE title_progress (
	type TEXT NOT NULL,
	id INT NOT NULL,

	-- These columns cannot default to NULL because of how sqlite treats NULL primary keys.
	season INT NOT NULL DEFAULT -1,
	episode INT NOT NULL DEFAULT -1,

	percent FLOAT NOT NULL,

	ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

	PRIMARY KEY (type, id, season, episode)
);

CREATE TABLE my_list (
	type TEXT NOT NULL,
	id INT NOT NULL,

	ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	title TEXT NOT NULL,
	genres TEXT NOT NULL,
	overview TEXT NOT NULL,
	released TIMESTAMP,
	trailer TEXT,
	rating TEXT,
	poster TEXT NOT NULL,

	PRIMARY KEY (type, id)
);

-- I figure if the index is ascending, sqlite won't have to resort it each time a title is added.
CREATE INDEX title_progress_ts ON title_progress (ts ASC);

CREATE INDEX my_list_ts ON my_list (ts ASC);
