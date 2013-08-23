quarry
======

A docker based runtime environment for [digger](https://github.com/binocarlos/digger) applications.

## installation

	$ wget -qO- https://raw.github.com/binocarlos/quarry/master/bootstrap.sh | sudo bash

## usage

make a new folder for an app

	$ mkdir /srv/myapp && cd /srv/myapp

initialize a new quarry/digger application

	$ quarry init .

run a digger/quarry application

	$ quarry run .

this will run the app by default in development mode which is all services in one container.

## background

quarry is a command-line tool that has the following jobs:

 * to launch digger applications from their digger.yml files
 * to allocate docker servers for each role to be launched on
 * to know what services the digger.yml contains
 * to export connection details to services in environment

## applications

Are folders containing digger.yml and code.

Each application is named after the github repo - e.g.

	binocarlos/mycoolapp

Once the .yml is parsed - we know what of the following are needed:

 * websites (express node.js app)
 * reception (core router)
 * switchboard (pub/sub server)
 * warehouses (generic javascript with $digger connection)
 * services (log-lived network services - redis - mongo)

We create a .quarry folder in the code repository

.quarry should be in .gitignore

## usage

Once you have installed, quarry is a command line application.


