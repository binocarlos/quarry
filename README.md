quarry
======

A docker based runtime environment for [digger](https://github.com/binocarlos/digger) applications.

## installation

	$ wget -qO- https://raw.github.com/binocarlos/quarry/master/bootstrap.sh | sudo bash

## usage

	$ cat ~/.ssh/id_rsa.pub | ssh domain.com "sudo gitreceive upload-key user"

## applications

A user has a folder with some digger code inside.


## deploy

They want to work on their code locally and push it when ready to deploy.

There are 2 options for this:

 * git - push directly to our git reciever
 * github - git hook onto our git reciever
 * dropbox - manual trigger -> api download that auto uploads to our git reciever

When they deploy they want a staging domain that is the code they pushed and a big phat LIVE button that will roll out the new code across the actual deployment.

The staging view is a single bundle (i.e. a one-process digger stack) that is connecting to the live resources.

So - if I have an app in my digger.yaml with domains:

 * myapp.com
 * www.myapp.com

Then in staging it would be:

 * staging.myapp.com
 * staging.www.myapp.com

## build

The code will have a digger.yaml - this tells us:

 * services
 * warehouses
 * reception config
 * apps

We need to run the build script inside the builder docker container that will turn the digger.yaml into Dockerfiles for each named service.

It also outputs a Dockerfile for the staging stack to run all in one process.

## services

There are a few types of Dockerfile

 * service - base linux + server
 * warehouse - node + code
 * app - node + code
 * hq - node + code
 * reception - node + code

We are running some global services:

 * load balancer
 * boss hq




## install notes

we must set the 

	$ sudo nano /etc/default/grub

	GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"

	$ sudo update-grub
	$ sudo shutdown -r +1

and reboot for the memory limitations to work

http://docs.docker.io/en/latest/installation/kernel/