quarry
======

A docker based runtime environment for [digger](https://github.com/binocarlos/digger) applications.

It is totally ripped from [dokku](https://github.com/progrium/dokku.git) which is an inspiration in Bash scripting : )

## installation

Get your newly minted server quarry ready:

	$ wget -qO- https://raw.github.com/binocarlos/quarry/master/bootstrap.sh | sudo bash

Gain git deploy capabilities by provided your public key to gitreceive (from your development machine):

	$ cat ~/.ssh/id_rsa.pub | ssh domain.com "sudo gitreceive upload-key user"

## purpose

To run node.js applications and the databases they need by doing a:

	$ git push quarry master

from the command line.

There are 3 types of application that quarry can run:

 * digger applications - these have a digger.yaml file
 * quarry applications - these have a .quarry folder
 * node.js applications - these have a index.js


