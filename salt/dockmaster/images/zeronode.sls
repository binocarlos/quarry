include:
  - dockmaster.images.node

docker-zeronode:
  file.recurse:
    - name: {{ pillar.prefix }}/dockmaster/dockerfiles/zeronode
    - source: salt://dockmaster/dockerfiles/zeronode
  cmd.wait:
    - name: sh buildimage.sh quarry/zeronode dockerfiles/zeronode
    - cwd: {{ pillar.prefix }}/dockmaster
    - require:
      - file: docker-node
    - watch:
      - file: docker-zeronode
      - file: docker-node