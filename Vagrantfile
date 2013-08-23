# -*- mode: ruby -*-
# vi: set ft=ruby :

############################################################
#############################################################
# A single server quarry setup
#
# this plays the role of a single HQ server that spawns containers on itself with no scalaing
#
# it is perfect for a local developer to work on a single application

BOX_NAME = ENV['BOX_NAME'] || "precise64"
BOX_URI = ENV['BOX_URI'] || "https://s3-us-west-2.amazonaws.com/squishy.vagrant-boxes/precise64_squishy_2013-02-09.box"

Vagrant.configure("2") do |config|

  config.vm.box = BOX_NAME
  config.vm.box_url = BOX_URI

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  ## fix the IP to a local sub-net
  config.vm.network :private_network, ip: "192.168.8.120"

  ## expose the main master web port
  config.vm.network :forwarded_port, guest: 80, host: 8080

  ## mount this repo onto /srv/quarry
  config.vm.synced_folder "./", "/srv/quarry"

  ## mount the folder above this repo as /srv/projects - this is for development purposes
  config.vm.synced_folder "../", "/srv/projects"

  ####################################################################################
  ####################################################################################
  ####################################################################################
  ####################################################################################
  ####################################################################################
  #
  #
  # this updates the kernel so we can use lxc containers and docker
  #
  #

  # Provision docker and new kernel if deployment was not done
  if Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/default/*/id").empty?
    pkg_cmd = "apt-get update -qq; apt-get install -q -y python-software-properties; " \
    # Add X.org Ubuntu backported 3.8 kernel
    pkg_cmd << "add-apt-repository -y ppa:ubuntu-x-swat/r-lts-backport; " \
      "apt-get update -qq; apt-get install -q -y linux-image-3.8.0-19-generic; "
    # Add guest additions if local vbox VM
    is_vbox = true
    ARGV.each do |arg| is_vbox &&= !arg.downcase.start_with?("--provider") end
    if is_vbox
      pkg_cmd << "apt-get install -q -y linux-headers-3.8.0-19-generic dkms; " \
        "echo 'Downloading VBox Guest Additions...'; " \
        "wget -q http://dlc.sun.com.edgesuite.net/virtualbox/4.2.12/VBoxGuestAdditions_4.2.12.iso; "
      # Prepare the VM to add guest additions after reboot
      pkg_cmd << "echo -e 'mount -o loop,ro /home/vagrant/VBoxGuestAdditions_4.2.12.iso /mnt\n" \
        "echo yes | /mnt/VBoxLinuxAdditions.run\numount /mnt\n" \
          "rm /root/guest_additions.sh; ' > /root/guest_additions.sh; " \
        "chmod 700 /root/guest_additions.sh; " \
        "sed -i -E 's#^exit 0#[ -x /root/guest_additions.sh ] \\&\\& /root/guest_additions.sh#' /etc/rc.local; " \
        "echo ''; " \
        "echo '-----------------------------------------------------------------------'; " \
        "echo 'Installation of VBox Guest Additions is proceeding in the background.'; " \
        "echo '-----------------------------------------------------------------------'; " \
        "echo ''; " \
        "echo 'type:'; " \
        "echo ''; " \
        "echo '   vagrant reload'; " \
        "echo ''; " \
        "echo '-----------------------------------------------------------------------'; " \
        "echo 'in about 2 minutes to restart vagrant and activate the new guest additions.'; " \
        "echo '-----------------------------------------------------------------------'; "
    end
    # Activate new kernel
    pkg_cmd << "shutdown -r +1; "

    ##############################################################
    ##############################################################
    ##############################################################
    # inline the command created above - this happens the very first time

    config.vm.provision :shell, :inline => pkg_cmd
  else

    ##############################################################
    ##############################################################
    ##############################################################
    # run the basic provisioning script
    #
    # this installs ansible as well as other core development packages

    config.vm.provision :shell, :inline => "QUARRY_ENV=development cd /srv/quarry && make install"

  end  

end