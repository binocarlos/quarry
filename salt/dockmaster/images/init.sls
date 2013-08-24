# here are the docker images themselves
# each one has dependencies and should re-build when the Dockerfile changes

# to remove all containers
#sudo docker rm `sudo docker ps -a -q`


# to remove all images with quarry in the tag
#sudo docker rmi `sudo docker images | grep quarry | awk '!/ID/ {print $3}' | sort`

# to remove all images full stop
#sudo docker rmi `sudo docker images | awk '!/ID/ {print $3}' | sort`

include:
  - dockmaster.images.base
  - dockmaster.images.hipache
  - dockmaster.images.mongo
  - dockmaster.images.redis  
  - dockmaster.images.node
  - dockmaster.images.zeronode
  