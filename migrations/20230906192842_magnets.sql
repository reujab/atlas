-- This table caches magnet links for 1 day and provides a UUID for the client to use.
CREATE TABLE magnets (
	magnet TEXT NOT NULL PRIMARY KEY,
	uuid UUID NOT NULL DEFAULT gen_random_uuid(),
	query TEXT NOT NULL,
	seasons INT[],
	episode INT,
	ts TIMESTAMP NOT NULL DEFAULT now()
);
