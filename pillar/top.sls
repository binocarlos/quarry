base:
  # everyone gets settings.sls
  '*':
    - all
  # we load up the cloud api keys for the master
  'saltmaster':
    
  # env settings
  'environment:development':
    - match: grain
    - development
  'environment:production':
    - match: grain
    - production