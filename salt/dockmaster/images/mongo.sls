include:
  - dockmaster.images.base

docker-mongo:
  file.recurse:
    - name: {{ pillar.prefix }}/dockmaster/dockerfiles/mongo
    - source: salt://dockmaster/dockerfiles/mongo
  cmd.wait:
    - name: sh buildimage.sh quarry/mongo dockerfiles/mongo
    - cwd: {{ pillar.prefix }}/dockmaster
    - require:
      - file: docker-base
    - watch:
      - file: docker-mongo
      - file: docker-base