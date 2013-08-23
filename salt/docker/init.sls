# new cloud servers booted with 3.8 have this done
# the development vagrant setup does this itself
{% if grains['update_aufs'] %}
docker-update-kernel:
  pkg:
    - installed
    - name: linux-image-extra-{{ salt['cmd.run']('uname -r') }}
{% endif %}

lxc-docker:
  pkgrepo:
    - managed
    - ppa: dotcloud/lxc-docker
    - require_in:
      - pkg: lxc-docker
  pkg:
    - installed
    - name: lxc-docker
    - refresh: True
    {% if grains['update_aufs'] %}
    - require:
      - pkg: docker-update-kernel
    {% endif %}

# here are the docker images themselves
# each one has dependencies and should re-build when the Dockerfile changes

#docker rm `docker ps -a -q`
#sudo docker images | grep quarry/base | awk '!/ID/ {print $3}' | sort

quarrydocks:
  file.directory:
    - name: /srv/quarrydocks/dockers
    - makedirs: True

docker-base:
  cmd.run:
    - name: docker rmi `docker images | grep quarry/base | awk '!/ID/ {print $3}' | sort` && docker build -t quarry/base .
    - cwd: /srv/quarrydocks/dockers/base
    - require:
      - file: dockerfiles

docker-hipache:
  cmd.run:
    - name: docker rmi `docker images | grep quarry/hipache | awk '!/ID/ {print $3}' | sort` && docker build -t quarry/hipache -q .
    - cwd: /srv/quarrydocks/dockers/hipache
    - require:
      - cmd: docker-base

docker-redis:
  cmd.run:
    - name: docker rmi `docker images | grep quarry/redis | awk '!/ID/ {print $3}' | sort` && docker build -t quarry/redis .
    - cwd: /srv/quarrydocks/dockers/redis
    - require:
      - cmd: docker-base

docker-mongo:
  cmd.run:
    - name: docker rmi `docker images | grep quarry/mongo | awk '!/ID/ {print $3}' | sort` && docker build -t quarry/mongo .
    - cwd: /srv/quarrydocks/dockers/mongo
    - require:
      - cmd: docker-base

docker-node:
  cmd.run:
    - name: docker rmi `docker images | grep quarry/node | awk '!/ID/ {print $3}' | sort` && docker build -t quarry/node .
    - cwd: /srv/quarrydocks/dockers/node
    - require:
      - cmd: docker-base

docker-zeronode:
  cmd.run:
    - name: docker rmi `docker images | grep quarry/zeronode | awk '!/ID/ {print $3}' | sort` && docker build -t quarry/zeronode .
    - cwd: /srv/quarrydocks/dockers/zeronode
    - require:
      - cmd: docker-node