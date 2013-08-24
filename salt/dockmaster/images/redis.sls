include:
  - dockmaster.images.base

docker-redis:
  file.recurse:
    - name: {{ pillar.prefix }}/dockmaster/dockerfiles/redis
    - source: salt://dockmaster/dockerfiles/redis
  cmd.wait:
    - name: sh buildimage.sh quarry/redis dockerfiles/redis
    - cwd: {{ pillar.prefix }}/dockmaster
    - require:
      - file: docker-base
    - watch:
      - file: docker-redis
      - file: docker-base