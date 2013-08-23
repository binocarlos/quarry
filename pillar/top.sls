base:
  '*':
    - settings
  'saltmaster':
    - cloud
  'environment:development':
    - match: grain
    - development
  'environment:production':
    - match: grain
    - production