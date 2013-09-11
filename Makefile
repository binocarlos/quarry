GITRECEIVE_URL ?= https://raw.github.com/progrium/gitreceive/master/gitreceive
SSHCOMMAND_URL ?= https://raw.github.com/progrium/sshcommand/master/sshcommand
PLUGINHOOK_URL ?= https://s3.amazonaws.com/progrium-pluginhook/pluginhook_0.1.0_amd64.deb
FIREWALL_REPO ?= https://github.com/bmaeser/iptables-boilerplate.git
QUARRYFILES_REPO ?= https://github.com/binocarlos/quarryfiles.git

PWD := $(shell pwd)

all: dependencies install plugins

install:
	cp -f quarry /usr/local/bin/quarry
	cp receiver /home/git/receiver
	mkdir -p /var/lib/quarry/plugins
	cp -r plugins/* /var/lib/quarry/plugins
	quarry install

quarryfiles:
	cd ~ && test -d quarryfiles || git clone ${QUARRYFILES_REPO}
	cd ~/quarryfiles && make all

uninstall:
	quarry cleanup
	rm -rf /usr/local/bin/quarry
	rm -rf /home/git/receiver
	rm -rf /var/lib/quarry/plugins
	rm -rf ~/quarryfiles

plugins: pluginhook docker
	quarry plugins-install

dependencies: firewall gitreceive sshcommand pluginhook docker

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
	usermod -aG docker vagrant
	curl https://get.docker.io/gpg | apt-key add -
	echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install -y lxc-docker 
	sleep 2 # give docker a moment i guess

aufs:
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`

# the firewall so we can expose ports amoungst containers but not worry about public access to them
# 22, 80 and 443 are let through
firewall:
	mkdir -p /etc/firewall
	mkdir -p /etc/firewall/custom
	cd ~ && test -d iptables-boilerplate || git clone ${FIREWALL_REPO}
	cp ~/iptables-boilerplate/firewall /etc/init.d/firewall
	cp ~/iptables-boilerplate/etc/firewall/*.conf /etc/firewall
	chmod 755 /etc/init.d/firewall
	update-rc.d firewall defaults
	# create a backup of the firewall rules and allow 22 and 80 and 443 through
	cp /etc/firewall/services.conf /etc/firewall/services.default.conf
	cat /etc/firewall/services.default.conf | sed -r 's/#((80|443)\/(tcp|udp))/\1/' > /etc/firewall/services.conf
	cp /etc/firewall/firewall.conf /etc/firewall/firewall.default.conf
	cat /etc/firewall/firewall.default.conf | sed -r 's/ipv4_forwarding=false/ipv4_forwarding=true/' > /etc/firewall/firewall.conf
	service firewall restart