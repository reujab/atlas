#!/bin/bash -e
set -o pipefail

cd "$(dirname "$0")/.."

panic() {
	echo "$@" 1>&2
	exit 1
}

args=("$@")
script=$0
usage() {
	if [[ ${#args[@]} != "$#" ]]; then
		panic "Usage: $script $*"
	fi
}

require() {
	for cmd; do
		which "$cmd" &> /dev/null || missing_cmds+=("$cmd")
	done
	if (( ${#missing_cmds[@]} )); then
		panic Missing tools: "${missing_cmds[@]}"
	fi
	set -x
}

require-server-env() {
	if [[ ! -d config/server.env ]]; then
		panic "You must copy config/{server.env.default => server.env} and set the variables."
	fi
}
