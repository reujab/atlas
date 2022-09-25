CREATE TABLE genres (
	id SMALLINT PRIMARY KEY,
	name TEXT NOT NULL,
	movie BOOLEAN,
	series BOOLEAN
);

CREATE TYPE type AS ENUM ('movie', 'tv');

CREATE TYPE rating AS ENUM (
	'G',
	'TV-G',
	'TV-Y',
	'TV-Y7',
	'TV-Y7-FV',

	'PG',
	'TV-PG',

	'PG-13',
	'TV-14',

	'R',
	'TV-MA',
	'NC-17',

	'NR'
);

CREATE TABLE titles (
	id INT,
	type type,
	ts TIMESTAMP,

	title TEXT,
	genres SMALLINT[],
	language CHAR(2),
	popularity FLOAT,
	rating rating,
	released DATE,
	runtime SMALLINT,
	score SMALLINT,
	votes INT,
	trailer VARCHAR(16),
	overview TEXT,

	PRIMARY KEY (id, type)
);

CREATE INDEX titles_ts ON titles (ts ASC NULLS FIRST, popularity DESC NULLS LAST);

CREATE INDEX titles_popularity ON titles (popularity DESC NULLS LAST);
