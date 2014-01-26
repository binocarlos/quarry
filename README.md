quarry
======

A git push stack deployment tool written in bash, using [Docker](https://docker.io) and heavily inspired by [Dokku](https://github.com/progrium/dokku).

Define your stack in a .yml file in the root of a repository - git push to quarry and it will spin up the services and worker nodes and route HTTP traffic to the web servers.

```
        HTTP
          |
     nginx router
          |
         / \
 xyz.com     abc.com
    |           |
----------------------
|    quarry stack    |
----------------------
|                    |
|      Workers       |
|                    | --- docker
|      Services      |     containers
|                    |
----------------------
          ^
          ^
          ^
$ git push quarry master
```

## example stack

Each quarry stack has a quarry.yml file in it's root.

This file describes what 'services' and 'workers' will be deployed when push to the server.

Services are long running things like databases that are not part of the codebase and do not restart on each push.

Workers are processes that restart on each push and usually make use of the codebase (e.g. node src/myserver.js).

Here is an example stack that defines 2 services (Mongo + Redis) and 1 web application and 1 static website.

```yaml
# a mongo database
mongo:
	# services stay running
  type: service
  # what docker image the service is based on
  container: quarry/mongo
  # keep data on the host
  volumes:
    - /data/db
  # what ports the service exposes
  expose:
    - 27017

# an etcd service
etcd:
  type: service
  container: quarry/etcd
  global: diggerhq-service-etcd
  volumes:
    - /data/db
  args: -name diggerhq
  expose:
    - 4001
    - 7001

redis:
  type: service
  container: quarry/redis
  volumes:
    - /data/db
  expose:
    - 6379

# an image is not a running process
# it is used by workers
baseapp:
  type: image
  # the dockerfile that creates the image
  dockerfile: |
    FROM quarry/monnode
    ADD ./src/lib /srv/app/src/lib
    ADD ./Makefile /srv/app/Makefile
    RUN cd /srv/app/src/lib/stack && npm install

# a worker is a long running process that restarts each time code is pushed
digger:
  type: worker
  # the dockerfile for the worker
  dockerfile: |
    FROM quarry/monnode
    ADD ./src/digger /srv/app
    RUN cd /srv/app && npm install
    WORKDIR /srv/app
    ENTRYPOINT NODE_ENV=production mon "node ./index.js --port 8080"
  # ports we will communicate to the worker on
  expose:
    - 8080
  # how to announce ourselves to the network
  hook: quarry yoda tracktube set /tracktube/digger/main $host:$port
  unhook: quarry yoda tracktube del /tracktube/digger/main

# this worker has a domains property so it will have HTTP traffic routed to it
website:
  type: worker
  dockerfile: |
    FROM tracktube/baseapp
    ADD ./src/website /srv/app/src/website
    RUN cd /srv/app/src/website && npm install    
    WORKDIR /srv/app
    ENTRYPOINT NODE_ENV=production mon "node ./src/website/index.js --port 80"
  # nginx will proxy requests for these domains
  domains:
    - "thetracktube.com"
    - "www.thetracktube.com"
    - "tracktube.local.digger.io"
    - "tracktube.lan.digger.io"
```

## installation

Run this on a nice and fresh cloud server - one that you have root ssh access to.

```
$ wget -qO- https://raw.github.com/binocarlos/quarry/master/bootstrap.sh | sudo bash
```

Then - generate SSH keys on your local machine and send them to your new server:

```
$ cat ~/.ssh/id_rsa.pub | ssh nicenewserver.com "sudo sshcommand acl-add quarry me"
```

Replace 'nicenewserver.com' with your server hostname and 'me' with your name (which represents the key you just uploaded)

You are ready to start pushing code!

Change to your project folder and add the quarry remote and push:
```
$ cd ~/myproject
$ git remote add quarry quarry@nicenewserver.com:myproject
$ git push quarry master
```

### development

You can use the included Vagrantfile to boot into a linux with docker installed (for Windows or Mac users).

```
$ cd quarry
$ vagrant up
```

Once the image has booted and you have SSH'd into the vagrant box:

```
$ wget -qO- https://raw.github.com/binocarlos/quarry/master/bootstrap.sh | sudo bash
```

## configure

To deploy a stack to quarry you need a git repository with a 'quarry.yml' at the root of the repo.

Each top level entry in the YAML file is a node in the stack that will be booted when you git push to quarry:

```yaml
nodename:
	type: service|worker
```

The 'type' setting of each node decides how the rest of the config is interpreted.

 * image - base images used by other parts of the stack
 * service - nodes that are started once and remain running (e.g. database servers)
 * worker - backend nodes that can expose TCP ports to other nodes and expose domains to the HTTP router

For each, there are a few core settings:

 * container - what Docker image the node is based on
 * dockerfile - the raw docker file to build the node

Each docker file is built in the root of the app so you can include code as you want.

The [Dockerfile Reference](http://docs.docker.io/en/latest/use/builder) is a good place to learn about Dockerfile commands.

### type: service

A service node will boot and stay running.

Services expose ports so that the rest of the stack can connect to them.

Take the config:

```yaml
mongo:
	type: service
	container: quarry/mongo
	expose:
		- 27017
```

It says - boot a container based on the "quarry/mongo" image and expose the following environment variables to the worker nodes:

 * MONGO_PORT=tcp://172.17.0.8:1234
 * MONGO_PORT_27017_TCP=tcp://172.17.0.8:1234
 * MONGO_PORT_27017_TCP_PROTO=tcp
 * MONGO_PORT_27017_TCP_ADDR=172.17.0.8
 * MONGO_PORT_27017_TCP_PORT=1234

This is the same pattern as the [Docker Link Command](http://docs.docker.io/en/latest/use/working_with_links_names/).

Worker nodes in the stack can use these environment variables to connect to the services.

Why not just use the docker link feature? Because quarry will soon have a multi-host meaning containers can still connect to each other even on different servers.

### type: worker

A worker is a long running process that restarts on each push.

If a worker has a 'domains' setting - the front end router will direct HTTP traffic to it.

Here is an example of a web node with some domains for the router:

```yaml
webnode:
  domains:
  	- abc.com
  	- efg.com
```

This means any requests for either 'abc.com' or 'efg.com' will end up at this node.

If a worker has a 'document_root' setting it means that the node is a static website and nginx will just serve the files from it.

## commands

Once a stack is running remotely - you can run commands from your local machine:

```
$ ssh -t quarry@hostname command
```

### mongo:cli stackname

connect to the remote mongo server for a stack

```
$ ssh -t quarry@domain.com mongo:cli mystack
```

### redis:cli stackname

connect to the remote mongo server for a stack

```
$ ssh -t quarry@domain.com mongo:cli mystack
```

## licence

MIT