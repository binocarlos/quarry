# new cloud servers booted with 3.8 have this done
# the development vagrant setup does this itself
docker-update-kernel:
  pkg:
    - installed
    - name: linux-image-extra-{{ salt['cmd.run']('uname -r') }}

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
    - require:
      - pkg: docker-update-kernel