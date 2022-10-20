ALTER SYSTEM SET shared_memory_type TO sysv;
ALTER SYSTEM SET random_page_cost TO 1;

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
	runtime INT,
	score SMALLINT,
	votes INT,
	trailer VARCHAR(16),
	overview TEXT,

	PRIMARY KEY (id, type)
);

CREATE INDEX titles_ts ON titles (ts ASC NULLS FIRST, popularity DESC NULLS LAST);

CREATE INDEX titles_popularity ON titles (popularity DESC NULLS LAST);

CREATE INDEX titles_score ON titles (score DESC NULLS LAST, popularity DESC NULLS LAST)
WHERE votes >= 1000;
