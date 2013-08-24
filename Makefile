ENV ?= development

install: dependencies

# used to symlink /vagrant/salt and /vagrant/pillar to /srv/quarry/salt and /srv/quarry/pillar
vagrant: dependencies

dependencies: salt-master salt-minion

salt-master:
	@echo "installing salt master"
	sh scripts/install_salt_master.sh

salt-minion:
	@echo "installing salt minion"
	sh scripts/install_salt_minion.sh
	service salt-minion restart
	
# used for cleaning up the dockmaster setup of docker images
clean:
	docker rm `docker ps -a -q`
	docker rmi `docker images | grep quarry/ | awk '!/ID/ {print $3}' | sort`
	rm -rf /srv/deployquarry

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