#!/bin/sh

source_dir=$(dirname $0)
cd $source_dir

clean_up() {
    exit
}

sedeasy_improved() {
    echo $3 | sed -e "s/$(
        echo "$1" | sed -e 's/\([[\/.*]\|\]\)/\\&/g' | sed -e 's:\t:\\t:g'
    )/$(
        echo "$2" | sed -e 's/[\/&]/\\&/g' | sed -e 's:\t:\\t:g'
    )/g"
}

trap clean_up HUP INT TERM

echo "Starting pet-tracker server with debuger from vscode"
REL_PWD=$(sedeasy_improved $HOME "~" $PWD)
window_title="${REL_PWD} - Visual Studio Code"
command_string="xdotool windowactivate --sync \$(xdotool search --name '$window_title' | head -n 1) key Ctrl+Shift+F5"
if [ "$OSTYPE" = "darwin"* ]; then
    command_string="osascript ./restart_debug_session.applescript"
fi
echo $command_string
echo $command_string >>local/docker_host.pipe
# echo 'code --open-url "vscode://vadimcn.vscode-lldb/restart?name=lldb_pet_tracker"' >> local/docker_host.pipe
# echo 'code --open-url "vscode://vadimcn.vscode-lldb/restart?name=lldb_pet_tracker,folder=%2fhome%2fdebian%2fapp"' >> local/docker_host.pipe

while true; do
    sleep 1
done
