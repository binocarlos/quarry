#
# installs zeromq ontop of the nodejs base image
#
FROM quarry/node
MAINTAINER Kai Davenport
RUN add-apt-repository -y ppa:chris-lea/zeromq
RUN apt-get update
RUN apt-get install -y libzmq3 libzmq3-dev