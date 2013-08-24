#
# CORE settings that are used for all servers
#
basepackages:
  - git
  - make
  - curl
dockmaster:
  images:
    - base
    - hipache
    - mongo
    - redis
    - node
    - zeronode
prefix: /srv/deployquarry
users:
  quarry:
    