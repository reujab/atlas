CREATE TABLE title_progress (
	type TEXT,
	id INT,

	season INT,
	episode INT,

	percent FLOAT,
	position FLOAT,

	PRIMARY KEY (type, id, season, episode)
);
