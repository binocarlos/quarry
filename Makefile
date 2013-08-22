ANSIBLE_URL ?= git://github.com/ansible/ansible.git
DOCKER_URL ?= https://launchpad.net/~dotcloud/+archive/lxc-docker/+files/lxc-docker_0.4.8-1_amd64.deb
DOCKER_BIN ?= https://s3.amazonaws.com/get.docker.io/builds/Linux/x86_64/docker-1004d57b85fc3714b089da4c457228690f254504

all: dependencies docker ansible install

install:
	echo "Installing quarry"

dependencies:
	apt-get update
	apt-get install -y git make curl

docker: aufs
	add-apt-repository ppa:dotcloud/lxc-docker -y
	apt-get update
	apt-get install lxc-docker -y

ansible:
	apt-get install python-jinja2 -y
	test -d /root/ansible || git clone ${ANSIBLE_URL} /root/ansible
	cd /root/ansible && make install

aufs:
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`