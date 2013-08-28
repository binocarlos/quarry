quarry
======

A docker based runtime environment for [digger](https://github.com/binocarlos/digger) applications.

## installation

	$ wget -qO- https://raw.github.com/binocarlos/quarry/master/bootstrap.sh | sudo bash

## usage

	$ cd <project_root>
	$ quarry build
	$ quarry run

### building

We must turn the digger.yaml file into a set of DockerFiles to run the stack.

We do this inside a 'quarry/builder' container.

VOLUME / 

	<project_root> -> /home/quarry_project

And then we run

This is use the quarry/buyil







