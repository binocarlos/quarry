QUARRY_VERSION = master
QUARRY_ROOT ?= /home/quarry
SSHCOMMAND_URL ?= https://raw.github.com/progrium/sshcommand/master/sshcommand
NGINXVHOST_URL ?= https://raw.github.com/binocarlos/nginx-vhost/master/bootstrap.sh
YODA_URL ?= https://raw.github.com/binocarlos/yoda/master/bootstrap.sh

.PHONY: all install copyfiles version dependencies sshcommand gitreceive docker aufs network test quarry-base

all:
	# Type "make install" to install.

thing:
	
install: dependencies copyfiles core version

copyfiles:
	cp -f quarry /usr/local/bin/quarry || true

version:
	git describe --tags > ${QUARRY_ROOT}/VERSION  2> /dev/null || echo '~${QUARRY_VERSION} ($(shell date -uIminutes))' > ${QUARRY_ROOT}/VERSION

core: quarry-base

quarry-base:
	docker build -t quarry/base .

dependencies: sshcommand docker network nginx-vhost

sshcommand:
	wget -qO /usr/local/bin/sshcommand ${SSHCOMMAND_URL}
	chmod +x /usr/local/bin/sshcommand
	sshcommand create quarry /usr/local/bin/quarry

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

yoda:
	wget -qO- ${YODA_URL} | sudo bash

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