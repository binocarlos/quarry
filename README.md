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
# a mongo database service
mongo:
	type: service
	container: quarry/mongo
	expose:
		- 27017

# a redis database service
redis:
	type: service
	container: quarry/redis
	expose:
		- 6379

# an app running node.js code
app:
	type: worker
	container: quarry/node
	install:
		- cd src/app && npm install
	run: node src/app/index.js
	domains:
		- myapp.com
		- *.myapp.com

# a static website
website:
	type: worker
	document_root: src/website/www
	domains:
		- mydomain.com
		- *.mydomain.com
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

 * service - nodes that are started once and remain running (e.g. database servers)
 * worker - backend nodes that can expose TCP ports to other nodes and expose domains to the HTTP router

For each, there are a few core settings:

 * container - what Docker image the node is based on
 * install - the command that installs the node's dependencies
 * run - the command that will execute the node

Container defines what docker image the node will use.

This is either a repository in the [Docker Index](https://index.docker.io/) or it is a path to a Dockerfile inside the repository.

Here is a node that is running from a custom Docker container build:

```yaml
custom_nodejs_worker:
	type: worker
	container ./src/worker
```

and the contents of ./src/worker/Dockerfile

```
FROM quarry/node
RUN apt-get install some-funky-dep
RUN useradd some-funky-user-thing
ADD . /srv/workerapp
EXPOSE 8791
ENTRYPOINT ["node", "/srv/workerapp/index.js"]
```

You can also define 'install' and 'run' steps in the quarry.yml.

Here is a node that is running based on the quarry/node image from the index but with custom installation and run steps layered over (in a automated Dockerfile):

```yaml
nodejs_worker:
  type: worker
  container: quarry/node
  install: cd src/worker && npm install
  run: node src/worker/index.js
```

This will be translated into the following Dockerfile:

```
FROM quarry/node
RUN cd /srv/app/src/worker && npm install
RUN useradd some-funky-user-thing
ENTRYPOINT node /srv/app/src/worker/index.js
```

Notice how the paths have been translated - it is important that you keep paths relative in your quarry.yml

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

## licence

MIT