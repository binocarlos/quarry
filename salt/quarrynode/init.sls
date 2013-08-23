# a quarrynode is a docker server that is 
# injecting it's pillar data from the quarry hq mongo database
#
# this means that we control:
#
#   server installations
#   docker containers
#
# the management of what container to spark on what quarrynode is up to the hq server
# this setup is using the pillar data the hq has prepared
include:
  - docker

# this is where we are pulling in the pillar data from mongo
#ext_pillar:
#  - mongo: {collection: dockworkers, id_field: minionid, re_pattern: \.example\.com}