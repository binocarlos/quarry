# -*- mode: ruby -*-
# vi: set ft=ruby :

############################################################
#############################################################
# A single server quarry setup
#
# this plays the role of a single HQ server that spawns containers on itself with no scalaing
#
# it is perfect for a local developer to work on a single application

Vagrant.configure("2") do |config|

  config.vm.define :master do |master|

    master.vm.box = "precise64"
    master.vm.box_url = "https://s3-us-west-2.amazonaws.com/squishy.vagrant-boxes/precise64_squishy_2013-02-09.box"

    master.vm.network :private_network, ip: "192.168.8.120"
    master.vm.network :forwarded_port, guest: 80, host: 8380
    master.vm.network :forwarded_port, guest: 22, host: 8322

    master.vm.synced_folder "../", "/srv/projects"
    master.vm.synced_folder "./", "/srv/quarry"

    ## run the setup for the salt master
    #master.vm.provision :shell, :path => "install_development.sh", :args => "development"

  end
  
end