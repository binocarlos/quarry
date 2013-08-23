ENV ?= development

install: dependencies
	@echo "installing quarry"

dependencies: salt-master salt-minion

salt-master:
	@echo "installing salt master"
	sh scripts/install_salt_master.sh

salt-minion:
	@echo "installing salt minion"
	sh scripts/install_salt_minion.sh
	wait 5
	service salt-minion restart
	

#gitreceive:
#	wget -qO /usr/local/bin/gitreceive ${GITRECEIVE_URL}
#	chmod +x /usr/local/bin/gitreceive
#	test -f /home/git/receiver || gitreceive init

#sshcommand:
#	wget -qO /usr/local/bin/sshcommand ${SSHCOMMAND_URL}
#	chmod +x /usr/local/bin/sshcommand
#	sshcommand create dokku /usr/local/bin/dokku

#pluginhook:
#	wget -qO /tmp/pluginhook_0.1.0_amd64.deb ${PLUGINHOOK_URL}
#	dpkg -i /tmp/pluginhook_0.1.0_amd64.deb

#docker: aufs
#	egrep -i "^docker" /etc/group || groupadd docker
#	usermod -aG docker git
#	usermod -aG docker dokku
#	apt-add-repository -y ppa:dotcloud/lxc-docker
#	apt-get update
#	apt-get install -y lxc-docker 
#	sleep 2 # give docker a moment i guess

#aufs:
#	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`

# this is when we have a quarry container build
#stack:
#	@docker images | grep progrium/buildstep || docker build -t progrium/buildstep ${STACK_URL}	