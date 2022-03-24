CREATE TABLE genres (
	id SMALLINT PRIMARY KEY,
	name TEXT NOT NULL
);

CREATE TABLE titles (
	-- IMDb id
	id TEXT PRIMARY KEY,
	-- gomostream slug
	slug TEXT NOT NULL,
	title TEXT,
	ts TIMESTAMP,

	genres SMALLINT[],
	language CHAR(2),
	overview TEXT,
	popularity FLOAT,
	released DATE,
	score SMALLINT,
	votes INT
);

CREATE TABLE movies (
	id TEXT PRIMARY KEY,
	quality SMALLINT NOT NULL
) INHERITS (titles);

CREATE TABLE series (
	id TEXT PRIMARY KEY
) INHERITS (titles);

CREATE TABLE episodes (
	id TEXT REFERENCES series,
	season INT NOT NULL,
	episode INT NOT NULL,
	PRIMARY KEY (id, season, episode)
);
