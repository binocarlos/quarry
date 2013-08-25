GITRECEIVE_URL ?= https://raw.github.com/progrium/gitreceive/master/gitreceive
SSHCOMMAND_URL ?= https://raw.github.com/progrium/sshcommand/master/sshcommand
PLUGINHOOK_URL ?= https://s3.amazonaws.com/progrium-pluginhook/pluginhook_0.1.0_amd64.deb
QUARRYFILES_URL ?= github.com/binocarlos/quarryfiles
PWD := $(shell pwd)

all: dependencies quarryfiles install plugins

link:
	ln -s $(PWD)/quarry /usr/local/bin/quarry

install:
	test -f /usr/local/bin/quarry || ln -s $(PWD)/quarry /usr/local/bin/quarry
	test -f /home/git/receiver || ln -s $(PWD)/receiver /home/git/receiver
	mkdir -p /var/lib/quarry
	@#cp -r plugins/* /var/lib/quarry/plugins
	ln -s $(PWD)/plugins /var/lib/quarry/plugins

uninstall:
	rm -rf /usr/local/bin/quarry
	rm -rf /home/git/receiver
	rm -rf /var/lib/quarry/plugins

plugins: pluginhook docker
	quarry plugins-install

dependencies: gitreceive sshcommand pluginhook docker quarryfiles

gitreceive:
	wget -qO /usr/local/bin/gitreceive ${GITRECEIVE_URL}
	chmod +x /usr/local/bin/gitreceive
	test -f /home/git/receiver || gitreceive init

sshcommand:
	wget -qO /usr/local/bin/sshcommand ${SSHCOMMAND_URL}
	chmod +x /usr/local/bin/sshcommand
	sshcommand create quarry /usr/local/bin/quarry

pluginhook:
	wget -qO /tmp/pluginhook_0.1.0_amd64.deb ${PLUGINHOOK_URL}
	dpkg -i /tmp/pluginhook_0.1.0_amd64.deb

docker: aufs
	egrep -i "^docker" /etc/group || groupadd docker
	usermod -aG docker git
	usermod -aG docker quarry
	apt-add-repository -y ppa:dotcloud/lxc-docker
	apt-get update
	apt-get install -y lxc-docker
	sleep 2 # give docker a moment i guess

aufs:
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`

# checks to see if we have built the quarry images - otherwise trigger the build script
quarryfiles:
	@docker images | grep quarry/ || ./scripts/buildimages all