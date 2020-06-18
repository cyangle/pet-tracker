#!/bin/sh
source_dir=$(dirname $0)
pipe=$source_dir/local/docker_host.pipe

[ -p "$pipe" ] || mkfifo -m 0600 "$pipe" || exit 1
while :; do
    while read -r cmd; do
        if [ "$cmd" ]; then
            printf 'Running %s ...\n' "$cmd"
            sh -c "$cmd"
        fi
    done <"$pipe"
done
