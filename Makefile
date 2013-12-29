QUARRY_VERSION = master
QUARRY_ROOT ?= /home/quarry

SSHCOMMAND_URL ?= https://raw.github.com/progrium/sshcommand/master/sshcommand
PLUGINHOOK_URL ?= https://s3.amazonaws.com/progrium-pluginhook/pluginhook_0.1.0_amd64.deb
NGINXVHOST_URL ?= https://raw.github.com/binocarlos/nginx-vhost/master/bootstrap.sh
YODA_URL ?= https://raw.github.com/binocarlos/yoda/master/bootstrap.sh
JSONSH_URL ?= https://raw.github.com/dominictarr/JSON.sh/master/JSON.sh

.PHONY: all install copyfiles version plugins pluginhook dependencies sshcommand gitreceive docker aufs network test registry quarry-base core etcd jsonsh

all:
	# Type "make install" to install.

thing:
	
install: dependencies copyfiles plugins core version

copyfiles:
	cp quarry /usr/local/bin/quarry || true
	mkdir -p /etc/quarry
	mkdir -p /var/lib/quarry/plugins
	mkdir -p /var/lib/quarry/data
	cp -r plugins/* /var/lib/quarry/plugins

version:
	git describe --tags > ${QUARRY_ROOT}/VERSION  2> /dev/null || echo '~${QUARRY_VERSION} ($(shell date -uIminutes))' > ${QUARRY_ROOT}/VERSION

plugins: pluginhook docker
	quarry plugins-install

core: quarry-base registry yoda
	quarry core:boot

quarry-base:
	docker build -t quarry/base .

registry:
	docker build -t quarry/registry registry

yoda: jsonsh
	rm -rf ~/yoda
	cd ~ && wget -qO- https://raw.github.com/binocarlos/yoda/master/bootstrap.sh | sudo bash

jsonsh:
	wget -O /usr/local/bin/json_parse ${JSONSH_URL}
	chmod a+x /usr/local/bin/json_parse

dependencies: sshcommand docker network

sshcommand:
	wget -qO /usr/local/bin/sshcommand ${SSHCOMMAND_URL}
	chmod +x /usr/local/bin/sshcommand
	sshcommand create quarry /usr/local/bin/quarry

pluginhook:
	wget -qO /tmp/pluginhook_0.1.0_amd64.deb ${PLUGINHOOK_URL}
	dpkg -i /tmp/pluginhook_0.1.0_amd64.deb

docker: aufs
	egrep -i "^docker" /etc/group || groupadd docker
	usermod -aG docker quarry
	curl https://get.docker.io/gpg | apt-key add -
	echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install -y lxc-docker 
	sleep 2 # give docker a moment i guess

aufs:
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`

nginx-vhost:
	wget -qO- ${NGINXVHOST_URL} | sudo bash
	sleep 1
	nginx-vhost useradd quarry

# enable ipv4 forwarding
network:
	sysctl -w net.ipv4.ip_forward=1
	sleep 1
	service docker restart
	sleep 1

test:
	@echo server test
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--reporter spec \
		--timeout 300 \
		--require should \
		--growl \
		test/test.js