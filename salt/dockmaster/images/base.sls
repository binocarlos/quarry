include:
  - dockmaster.build

docker-base:
  file.recurse:
    - name: {{ pillar.prefix }}/dockmaster/dockerfiles/base
    - source: salt://dockmaster/dockerfiles/base
  cmd.wait:
    - name: sh buildimage.sh quarry/base dockerfiles/base
    - cwd: {{ pillar.prefix }}/dockmaster
    - require:
      - file: {{ pillar.prefix }}/dockmaster/buildimage.sh 
    - watch:
      - file: docker-base