base:
  'saltmaster':
    - saltcloud
    - dockmaster
  '*':
    - users
    - docker