# bits

the things needed to run a quarry stack

## Servers

Each server in a quarry cluster will run:

 * docker
 * etcd
 * SSHD + quarry public key

### Docker

http://docs.docker.io/en/latest/use/host_integration/

## HQ

The HQ server will be the git push endpoint and have SSH public & private keys for the quarry user.

When new servers are provisioned - they will have this public key in /home/quarry/.ssh/authorized_keys.

The master can then:

```
$ ssh quarry@hostname
```

## quarry.yml

On a git push - a quarry container is used to process the quarry.yaml file.

From this file come these nodes:

 * service - run once don't restart containers - write network into etcd -> env
 * web - restart and load-balance HTTP based on domains

The HQ must know about:

 * stacks - what stacks have been deployed and their current status (live disabled etc)
 * grid - what servers we have and what is actively running where 

Each stack must know about:

 * services - the long-running containers that have their details written into the env
 * env - the environment injected into each non-service container
 * nodes - containers that are restarted after each git push

## cli

The cli on the development machine must for the whole server:
 
 * ps - list the remote processes running across all stacks
 * servers - show the servers running
 * grid - show the allocation of processes onto servers

The cli on the development machine must for one stack:

 * start - run the whole stack locally
 * stop - stop the whole stack locally
 * ps - list the remote processes running in this stack
 * scale - change the number of containers for a node 
 * grid - show a virtual grid of processes

## components

Parts of the quarry core:

 * etc - the config for quarry itself
 * db - the data store for the current state
 * cloud - how to add delete servers from the grid
 * build - turn a repo + quarry.yml into launch instructions
 * launch - run/kill jobs on a given machine and report back
 * grid - the current allocation of processes onto servers
 * router - the nginx-vhost setup that is the public IP routing to all web nodes
 * config - distributed config for network (like hosts file)
 * network - IP tables setup that only allows communication to other quarry hosts + 22 + 80
 
## etc

The /etc/quarry folder contains:

 * env folder - global environment variables for the entire quarry stack
 * cloud - cloud settings
  * digital_ocean_api_key
  * digital_ocean_secret
 * hostnames - a hostname file for root domains

## db

Quarry keeps its current state in /home/quarry.

Folders of interest:

 * stacks - the folder with one folder per stack
 * servers - a folder with one file per server
 * grid - a folder with a json file describing the current grid

### /stacks

One folder per app deployed.  Each app folder contains:

 * env - one file per env value to be injected into new containers
 * src - the code that was most recently git pushed
 * build - the output of compiling quarry.yml

### /servers

Each server is represented as a folder with these files:

 * settings.json - the full instance record
 * id - single value file
 * ip - single value file
 * hostname - single value file
 * env - a folder with env vars for each container running on the host

### /grid

The current allocation of processes onto instances saved as a .json file

## cloud

The core quarry config will configure which cloud library to use for:

 * add(ram, done) - create a new server
 * remove(id, done) - remove an existing server

## build

We need to compile the quarry.yml into the launch steps.

process:

 1. git push
 2. copy code -> /stacks/$APPNAME/src
 3. cat quarry.yml -> quarry/root compile -> tar -> /stacks/$APPNAME/build

## launch

The launch step means going down all of the launch instructions and getting that work done.

For each launch instruction - the grid will need to be consulted for the instance address to deploy to.

Each instruction is one of:

 * ENSURE - boot a container unless it is already booted
 * DEPLOY - list the currently running containers - boot news ones then stop old ones
 * SCALE - add/remove processes for a node
 * ROUTE - add/remove domains to the router for a node
 * KILL - stop a running container

## grid

When the launch step is booting a container it will request an instance from the grid

The grid is what triggers the cloud library to add / remove instances.

It will create new instances if required to add the new blocks.

## router

nginx-vhost setup that routes domains exposed by web nodes.

## config

a collection of files that when written to will duplicate out to all servers in the network.

Notable files:

 * /etc/hosts

## network

IP tables setup so that when hosts are added to the network they are allowed to communicate to each other.

Each host will have port 22 public.

The router host will have port 22 and port 80 public.

# modules

## quarry

Command line tools for running quarry stacks either locally or deployment to live.

Tools:

 * run - run a whole stack locally
 * deploy - post git push -> trigger build -> launch
 * build - process the quarry.yml into launch instructions
 * launch - process a single launch instruction

## slicegrid

```
         -----    -----
         |___|    |   |
-----    |###|    |___|
|___|    |###|    |###|
|###|    |###|    |###|
-----    -----    -----
```

Object that represents a list of blocks and the allocation of slices onto those blocks.

Each block has:

 * size
 * used
 * free

Each slice has:

 * id
 * size

The options of the grid:

 * autosize(boolean) - should the grid automatically move stuff around to free up nodes
 * min - the minimum number of blocks that should exist
 * max - the maximum number of blocks that should exist
 * file - the path of the datastore for the grid

The methods of the grid:

 * add(id, size, tags, done) - add a block - done is called with the slice that was choosen
 * remove(id, done) - remove a block

The events the grid emits:

 * added - when a block has been added to a slice.
 * removed - when a block has been removed from a slice.
 * create - when a new slice is required because the grid is full.
 * destroy - when a slice can be destroyed because it is empty.

the grid knows where to deploy a job based on the current allocation.

```js
var SliceGrid = require('slicegrid');

var grid = new SliceGrid({
	autosize:true,
	min:1,
	max:10,
	file:'/srv/grid.json'
})

grid.on('create', function(slice, done){
	// create a new server any which way - return the settings for it
	cloudlib.createServer(done);
})

grid.on('destroy', function(block, done){
	// destroy the server using it's details
	cloudlib.destroyServer(block.id, done);
})

grid.on('added', function(block, slice, done){
	// deploy the job
	dockerlib.runContainer(block, slice, done);
})

grid.on('removed', function(block, slice, done){
	// kill the job
	dockerlib.killContainer(block, slice, done);
})

```

## pacific

A node/bash library for managing a fleet of digital ocean servers.

https://www.digitalocean.com/community/articles/how-to-scale-your-infrastructure-with-digitalocean

methods:

 * add(size, done) - add a new server with the specific amount of RAM
 * remove(id, done) - remove a server
 * resize(id, size, done) - resize an existing server

events:
 * 'added' - id, data
 * 'removed' - id
 * 'resized' - id, data

## locknet

A bash iptables wrapper that takes a list of host names and restricts communication between those hosts.

e.q. /my/hosts

```
1.2.3.4
1.2.3.5
1.2.3.6
```

```
locknet `cat /my/hosts`
```