GITRECEIVE_URL ?= https://raw.github.com/progrium/gitreceive/master/gitreceive
QUARRYFILES_URL ?= https://github.com/binocarlos/quarryfiles.git

PWD := $(shell pwd)

all: dependencies install

install:
	cp -f quarry /usr/local/bin/quarry
	chmod a+x /usr/local/bin/quarry
	cp receiver /home/git/receiver
	@echo "dont forget to add admin group non password sudo"

uninstall:
	rm -f /usr/local/bin/quarry
	rm -rf /home/git/receiver

dependencies: gitreceive docker nginx network quarryfiles

gitreceive:
	wget -qO /usr/local/bin/gitreceive ${GITRECEIVE_URL}
	chmod +x /usr/local/bin/gitreceive
	test -f /home/git/receiver || gitreceive init

quarryfiles:
	cd ~ && test -d quarryfiles || git clone ${QUARRYFILES_URL}
	cd ~/quarryfiles && make all

nginx:
	add-apt-repository -y ppa:nginx/stable
	apt-get update
	apt-get install -y nginx
	# this lets us sudo service nginx restart
	groupadd -f admin
	usermod -aG admin git
	mkdir -p /home/git/nginx
	chown -R git:admin /home/git/nginx
	chmod 0775 /home/git/nginx
	echo "include /home/git/nginx/*.conf;" > /etc/nginx/conf.d/quarry.conf
	sed -i 's/# server_names_hash_bucket_size/server_names_hash_bucket_size/' /etc/nginx/nginx.conf
	/etc/init.d/nginx start

docker: aufs
	egrep -i "^docker" /etc/group || groupadd docker
	usermod -aG docker git	
	curl https://get.docker.io/gpg | apt-key add -
	echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install -y lxc-docker 
	sleep 2 # give docker a moment i guess

# enable ipv4 forwarding
network:
	sysctl -w net.ipv4.ip_forward=1
	sleep 1
	service docker restart
	sleep 1

aufs:
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`

# the firewall so we can expose ports amoungst containers but not worry about public access to them
# 22, 80 and 443 are let through
#firewall:
#	mkdir -p /etc/firewall
#	mkdir -p /etc/firewall/custom
#	cd ~ && test -d iptables-boilerplate || git clone ${FIREWALL_REPO}
#	cp ~/iptables-boilerplate/firewall /etc/init.d/firewall
#	cp ~/iptables-boilerplate/etc/firewall/*.conf /etc/firewall
#	chmod 755 /etc/init.d/firewall
#	update-rc.d firewall defaults
#	# create a backup of the firewall rules and allow 22 and 80 and 443 through
#	cp /etc/firewall/services.conf /etc/firewall/services.default.conf
#	cat /etc/firewall/services.default.conf | sed -r 's/#((80|443)\/(tcp|udp))/\1/' > /etc/firewall/services.conf
#	cp /etc/firewall/firewall.conf /etc/firewall/firewall.default.conf
#	cat /etc/firewall/firewall.default.conf | sed -r 's/ipv4_forwarding=false/ipv4_forwarding=true/' > /etc/firewall/firewall.conf
#	service firewall restart