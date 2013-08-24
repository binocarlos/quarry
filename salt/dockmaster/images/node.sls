include:
  - dockmaster.images.base

docker-node:
  file.recurse:
    - name: {{ pillar.prefix }}/dockmaster/dockerfiles/node
    - source: salt://dockmaster/dockerfiles/node
  cmd.wait:
    - name: sh buildimage.sh quarry/node dockerfiles/node
    - cwd: {{ pillar.prefix }}/dockmaster
    - require:
      - file: docker-base
    - watch:
      - file: docker-node
      - file: docker-base