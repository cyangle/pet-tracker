#!/bin/sh
echo "Start reading from pipe"
source_dir=$(dirname $0)
cd $source_dir
echo "in create_and_read_host_pipe.sh" >> vscode.log
pipe=$source_dir/local/docker_host.pipe

echo "Create pipe for shell commands from dev container to execute" >> vscode.log

[ -p "$pipe" ] || mkfifo -m 0600 "$pipe" || exit 1
echo "wait for shell commands from dev container to execute" >> vscode.log
while true; do
    while read -r cmd; do
        if [ "$cmd" ]; then
            printf 'Running %s ...\n' "$cmd"
            sh -c "$cmd"
        fi
    done <"$pipe"
done
