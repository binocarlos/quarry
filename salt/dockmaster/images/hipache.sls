include:
  - dockmaster.build

docker-hipache:
  file.recurse:
    - name: {{ pillar.prefix }}/dockmaster/dockerfiles/hipache
    - source: salt://dockmaster/dockerfiles/hipache
  cmd.wait:
    - name: sh buildimage.sh quarry/hipache dockerfiles/hipache -q
    - cwd: {{ pillar.prefix }}/dockmaster
    - require:
      - file: {{ pillar.prefix }}/dockmaster/buildimage.sh 
    - watch:
      - file: docker-hipache