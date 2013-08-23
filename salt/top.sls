base:
  'saltmaster':
    - saltcloud
  '*':
    - users
    - docker