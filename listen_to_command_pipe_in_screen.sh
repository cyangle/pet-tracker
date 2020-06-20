#!/bin/sh

source_dir=$(dirname $0)
cd $source_dir

echo "in listen"

screen -ls pet_tracker_pipe | grep -i 'No Sockets found'
if [ $? -eq 0 ] ; then
  screen -dm -S pet_tracker_pipe /bin/sh ./create_and_read_host_pipe.sh
fi

screen -ls
