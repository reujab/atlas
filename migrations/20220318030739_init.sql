CREATE TABLE genres (
	id SMALLINT PRIMARY KEY,
	name TEXT NOT NULL,
	movie BOOLEAN,
	series BOOLEAN
);

CREATE TABLE titles (
	id INT,
	movie BOOLEAN,
	ts TIMESTAMP,

	genres SMALLINT[],
	language CHAR(2),
	overview TEXT,
	popularity FLOAT,
	released DATE,
	runtime SMALLINT,
	tagline TEXT,
	title TEXT,
	trailer VARCHAR(16),
	score SMALLINT,
	votes INT,

	PRIMARY KEY (id, movie)
);

CREATE INDEX titles_popularity ON titles (popularity DESC NULLS LAST);

CREATE TABLE seasons (
	id INT,
	season SMALLINT,
	episodes SMALLINT,
	name TEXT,
	overview TEXT,
	PRIMARY KEY (id, season, episodes)
);
