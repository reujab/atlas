#!/bin/bash -e
. ~/.env
export TMDB_KEY
PORT=8000 KEY=$SEEDBOX_KEY node .
