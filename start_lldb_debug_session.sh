#!/bin/sh

source_dir=$(dirname $0)
cd $source_dir

clean_up() {
	exit
}

trap clean_up HUP INT TERM


echo "Starting pet-tracker server with debuger from vscode"
window_title="${PWD/~/\~} - Visual Studio Code"
echo "xdotool windowactivate --sync $(xdotool search --name $window_title | head -n 1) key ctrl+shift+f5" >> ../local/docker_host.pipe
# echo 'code --open-url "vscode://vadimcn.vscode-lldb/restart?name=lldb_pet_tracker"' >> ../local/docker_host.pipe
# echo 'code --open-url "vscode://vadimcn.vscode-lldb/restart?name=lldb_pet_tracker,folder=%2fhome%2fdebian%2fapp"' >> ../local/docker_host.pipe

while true; do
    sleep 1
done
