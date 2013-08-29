GITRECEIVE_URL ?= https://raw.github.com/progrium/gitreceive/master/gitreceive
SSHCOMMAND_URL ?= https://raw.github.com/progrium/sshcommand/master/sshcommand
PLUGINHOOK_URL ?= https://s3.amazonaws.com/progrium-pluginhook/pluginhook_0.1.0_amd64.deb
FIREWALL_REPO ?= https://github.com/bmaeser/iptables-boilerplate.git

PWD := $(shell pwd)

all: dependencies install plugins build

link:
	ln -s $(PWD)/quarry /usr/local/bin/quarry

install:
	# fake install that symlinks to here
	test -f /usr/local/bin/quarry || ln -s quarry /usr/local/bin/quarry
	test -f /home/git/receiver || ln -s receiver /home/git/receiver
	# where the plugins live
	mkdir -p /var/lib/quarry
	# where the uploaded apps live
	mkdir -p /home/quarry
	@#cp -r plugins/* /var/lib/quarry/plugins
	test -d /var/lib/quarry/plugins || ln -s plugins /var/lib/quarry/plugins

uninstall:
	quarry cleanup
	rm -rf /usr/local/bin/quarry
	rm -rf /home/git/receiver
	rm -rf /var/lib/quarry/plugins

plugins: pluginhook docker
	quarry plugins-install

dependencies: gitreceive sshcommand pluginhook firewall docker

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

firewall:
	mkdir -p /etc/firewall
	mkdir -p /etc/firewall/custom
	cd ~ && test -d iptables-boilerplate || git clone $FIREWALL_REPO
	cp ~/iptables-boilerplate/firewall /etc/init.d/firewall
	cp ~/iptables-boilerplate/etc/firewall/*.conf /etc/firewall
	chmod 755 /etc/init.d/firewall
	update-rc.d firewall defaults
	# create a backup of the firewall rules and allow 22 and 80 and 443 through
	cp /etc/firewall/services.conf /etc/firewall/services.default.conf
	cat /etc/firewall/services.default.conf | sed -r 's/#((80|443)\/(tcp|udp))/\1/' > /etc/firewall/services.conf
	service firewall restart

docker: aufs
	egrep -i "^docker" /etc/group || groupadd docker
	usermod -aG docker git
	usermod -aG docker quarry
	curl http://get.docker.io/gpg | apt-key add -
	echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install -y lxc-docker
	sleep 2 # give docker a moment i guess

aufs:
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`

# checks to see if we have built the quarry images - otherwise trigger the build script
build:
	@docker images | grep quarry/ || quarry buildall
