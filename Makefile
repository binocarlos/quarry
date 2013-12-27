QUARRY_VERSION = master
QUARRY_ROOT ?= /home/quarry

SSHCOMMAND_URL ?= https://raw.github.com/progrium/sshcommand/master/sshcommand
NGINXVHOST_URL ?= https://raw.github.com/binocarlos/nginx-vhost/master/bootstrap.sh
PLUGINHOOK_URL ?= https://s3.amazonaws.com/progrium-pluginhook/pluginhook_0.1.0_amd64.deb

.PHONY: all install copyfiles version plugins dependencies sshcommand pluginhook docker aufs network test

all:
	# Type "make install" to install.

install: dependencies copyfiles plugins version

copyfiles:
	cp quarry /usr/local/bin/quarry
	mkdir -p /var/lib/quarry/plugins
	cp -r plugins/* /var/lib/quarry/plugins

version:
	git describe --tags > ${QUARRY_ROOT}/VERSION  2> /dev/null || echo '~${QUARRY_VERSION} ($(shell date -uIminutes))' > ${QUARRY_ROOT}/VERSION

plugins: pluginhook docker
	quarry plugins-install

dependencies: sshcommand pluginhook docker network

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
	wget -qO- ${NGINXVHOST_URL} | bash
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