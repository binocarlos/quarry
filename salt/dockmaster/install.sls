include:
  - docker

{{ pillar.prefix }}/dockmaster:
  file.directory:
    - makedirs: True

{{ pillar.prefix }}/dockmaster/buildimage.sh:
  file.managed:
    - source: salt://dockmaster/buildimage.sh
    - require:
      - file: {{ pillar.prefix }}/dockmaster