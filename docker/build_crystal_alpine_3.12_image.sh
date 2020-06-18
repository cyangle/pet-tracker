#!/bin/sh

source_dir=$(dirname $0)
cd $source_dir
docker build -f crystal.Dockerfile -t crystal:alpine-3.12 .
