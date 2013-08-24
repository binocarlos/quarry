# new cloud servers booted with 3.8 have this done
# the development vagrant setup does this itself
docker-update-kernel:
  cmd.run:
    - name: apt-get install -y linux-image-extra-`uname -r`
    - unless: lsmod | grep aufs || modprobe aufs

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
      - cmd: docker-update-kernel