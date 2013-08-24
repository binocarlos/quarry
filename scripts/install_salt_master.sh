#!/bin/bash

ENV=${1:-development}

if [ -d "/etc/salt" ]; then
  exit
fi

echo "------> Bootstrapping master for environment $ENV"

__apt_get_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@
}

apt-get update
__apt_get_noinput python-software-properties curl debconf-utils
apt-get update

# We're using the saltstack canonical bootstrap method here to stay with the
# latest open-source efforts
#
# Eventually, we can come to settle down on our own way of bootstrapping
\curl -L http://bootstrap.saltstack.org | sudo sh -s -- -M stable

# Set the hostname
echo """
127.0.0.1       localhost
127.0.1.1       saltmaster
""" > /etc/hosts
echo "saltmaster" > /etc/hostname
hostname `cat /etc/hostname`

echo """
run_as: root

open_mode: False
auto_accept: False

worker_threads: 3

file_roots:
  base:
    - /srv/quarry/salt

pillar_roots:
  base:
    - /srv/quarry/pillar

ext_pillar:
  - cmd_yaml: test -f /etc/quarry/pillar && cat /etc/quarry/pillar

peer:
  .*:
    - network.ip_addrs
    - grains.*

master: 127.0.0.1
grains:
  environment: $ENV
""" > /etc/salt/master


echo """
### This is controlled by the hosts file
master: saltmaster

id: saltmaster

grains:
  environment: $ENV

log_file: /var/log/salt/minion
log_level: info
log_level_logfile: garbage
""" > /etc/salt/minion