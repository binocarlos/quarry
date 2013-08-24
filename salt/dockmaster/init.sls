include:
  - docker

{{ pillar.prefix }}/dockmaster:
  file.directory:
    - makedirs: True
    - require:
      - pkg: lxc-docker

# we loop each docker image giving it a change to add flags to docker build
{% set images = ['base', 'hipache', 'mongo', 'redis', 'node', 'zeronode'] %}
{% for image in images %}
docker-{{ image }}:
  file.recurse:
    - name: {{ pillar.prefix }}/dockmaster/dockerfiles/{{ image }}
    - source: salt://dockmaster/dockerfiles/{{ image }}
  cmd.run:
    # docker build -q -t quarry/hipache dockerfiles/hipache
    - name: docker build -q -t quarry/{{ image }} dockerfiles/{{ image }}
    - cwd: {{ pillar.prefix }}/dockmaster
    # only build the image if it is not already built
    - unless: docker images | grep quarry/{{ image }}
    - require:
      - file: docker-{{ image }}
{% endfor %}