#!/usr/bin/env bash
id=$(docker ps -a | grep "etcd34" | awk '{ print $1 }')
echo $id
echo "done"