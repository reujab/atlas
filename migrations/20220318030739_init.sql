CREATE TABLE genres (
	id SMALLINT PRIMARY KEY,
	name TEXT NOT NULL
);

CREATE TABLE genres_movie (
	id SMALLINT PRIMARY KEY
) INHERITS (genres);

CREATE TABLE genres_tv (
	id SMALLINT PRIMARY KEY
) INHERITS (genres);

CREATE TABLE titles (
	id INT,
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
	votes INT
);

CREATE TABLE movies (
	id INT PRIMARY KEY
) INHERITS (titles);

CREATE TABLE series (
	id INT PRIMARY KEY
) INHERITS (titles);

CREATE TABLE seasons (
	id INT REFERENCES series,
	season SMALLINT,
	episodes SMALLINT,
	name TEXT,
	overview TEXT,
	PRIMARY KEY (id, season, episodes)
);
