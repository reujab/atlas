#!/bin/bash -e
. ~/.env
export TMDB_KEY DATABASE_URL
PORT=8000 node --enable-source-maps .
