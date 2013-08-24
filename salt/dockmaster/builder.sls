# here are the docker images themselves
# each one has dependencies and should re-build when the Dockerfile changes

#docker rm `docker ps -a -q`
#sudo docker images | grep quarry/base | awk '!/ID/ {print $3}' | sort

include:
  - dockmaster.install
  - dockmaster.images