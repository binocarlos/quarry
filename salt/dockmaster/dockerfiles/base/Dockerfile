# a base container that has updated from apt-get
# and installs supervisor ready for services to be booted
from ubuntu
# does a comment affect the cache?
MAINTAINER Kai Davenport
run echo "test2"
run	echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
run	apt-get -y update
run	apt-get -y install git make supervisor