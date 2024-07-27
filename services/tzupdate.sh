#!/bin/bash -ex
nm-online -t 2073600
tz=$(tzupdate -p)
ln -sf "/usr/share/zoneinfo/$tz" /var/local/localtime
