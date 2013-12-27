quarry
======

A [Docker](https://docker.io) and [etcd](https://github.com/coreos/etcd) based tool that deploys application stacks with a git push.

Much inspiration taken from [Dokku](https://github.com/progrium/dokku).

```
       Internet

          |
          |

       Edge Tier
                                
       /  |  \                  
      /   |   \
 xyz.com  |  abc.com

      Web Tier ------
                      \ 
     \/   |   \/       \      
     /\   |   /\       /  Database Tier       
    /  \  |  /  \     /
                     /
     Worker Tier ---

```
## installation

```
$ wget -qO- https://raw.github.com/binocarlos/quarry/master/bootstrap.sh | sudo bash
```

Do this on your local development machine and on a new cloud server - 3.8 kernel needed

## example stack

A quarry.yml that boots a stack with database, web and backend nodes.

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
	type: web
	container: quarry/node
	install:
		- cd src/app && npm install
	run: node src/app/index.js
	domains:
		- myapp.com
		- *.myapp.com

# a worker running node.js code
db:
	type: worker
	container: quarry/node
	install:
		- cd src/db && npm install
	run: node src/db/index.js

# values exported to the environment of each node
settings:
	type: config
	include: /home/private/tokens.yml
	speed: 10
	color: red
```


## configure

To deploy a stack to quarry you need a git repository with a 'quarry.yml' at the root of the repo.

Each top level entry in the YAML file is a node in the stack:

```yaml
nodename:
	type: nodetype
```

The type setting of each node decides how the rest of the config is interpreted.

The type drives the quarry module system allowing other new exotic types to be added later.

The current types are:

 * config - settings that are exposed as environment variables to nodes
 * service - nodes that are started once and remain running (e.g. database servers)
 * web - www nodes that serve HTTP requests and expose domains that are load-balanced by nginx
 * worker - backend nodes that can expose TCP ports to other nodes
 
### type: config
A config node will write each value to the environment of each node in the stack.

Take this config:

```yaml
settings:
	type: config
	include: /home/private/tokens.yml
	speed: 10
	color: red
```

The include field will load the contents of /home/private/tokens.yml into settings.  This is useful to include OAuth tokens that are not part of the codebase.

An example of /home/private/tokens.yml

```
facebook_oauth_id: 1234
facebook_oauth_secret: apples
```

The environment of each node in the stack will contain:

 * SETTINGS_SPEED = 10
 * SETTINGS_COLOR = red
 * SETTINGS_FACEBOOK_OAUTH_ID = 1234
 * SETTINGS_FACEBOOK_OAUTH_SECRET= apples

### nodes
Nodes in a quarry stack are service, web or worker nodes.

For each, there are a few important settings:

 * container - what Docker image the node is based on
 * install - the command that installs the node's dependencies
 * run - the command that will execute the node

#### container 
Defines the image the node will boot into.

This is either a repository in the [Docker Index](https://index.docker.io/) or it is a local path to a Dockerfile.

Here is a node that is running based on the quarry/node image:

```yaml
nodejs_worker:
  type: worker
  container: quarry/node
  install: cd src/worker && npm install
  run: node src/worker/index.js
```

Here is a node that is running from a custom Docker container build:

```yaml
custom_nodejs_worker:
	type: worker
	container ./src/worker/Dockerfile
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

The [Dockerfile Reference](http://docs.docker.io/en/latest/use/builder) is a good place to learn about Dockerfile commands.

#### install

The command that will prepare the node before running it.  The install command is optional as you can also do your installation steps using a custom Dockerfile.

The command will be run from the root of the application repo.

#### run
The command that will run the node itself.

The command will be run from the root of the application repo.

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

It says - boot a container based on the "quarry/mongo" image and expose the following environment variables to web and worker nodes:

 * MONGO_PORT=tcp://172.17.0.8:1234
 * MONGO_PORT_27017_TCP=tcp://172.17.0.8:1234
 * MONGO_PORT_27017_TCP_PROTO=tcp
 * MONGO_PORT_27017_TCP_ADDR=172.17.0.8
 * MONGO_PORT_27017_TCP_PORT=1234

The name of the environment variables is decided by:

 * the name of the service (mongo)
 * the ports exposed by the service (27017)

The pattern is:

```
<NAME>_PORT_<PORT>
MONGO_PORT_27017
```

This is the same pattern as the [Docker Link Command](http://docs.docker.io/en/latest/use/working_with_links_names/).

Other nodes in the stack can use these environment variables to connect to the services.

### type: web

A web node is a HTTP serving process that will have traffic routed to it based on domain name.

It will have a 'domains' setting which is a list of the domains that should be routed to this web node.

Here is an example of a web node with some domains for the router:

```yaml
webnode:
  domains:
  	- abc.com
  	- efg.com
```

### type: worker

A worker node is any kind of process that will not be publically routed to.

Worker nodes can expose ports like service nodes can but the routing details are not written to the environment like the services.

This is because worker nodes can come and go whereas services remain running.

quarry comes with an etcd server running on each instance and each stack will register it endpoints with the etcd server.

quarry will register the endpoints for each node with the etcd server with the following pattern:

	/stackname/nodename/pid

So - if we have a 'mongo' service running in a 'test' stack - we can read all endpoints using:

```
curl -L http://127.0.0.1:4001/v2/keys/test/mongo
```

The same goes for worker nodes.  Web nodes will probably want to contact worker nodes to give them work.

They can listen to the etcd servers to be told about new workers coming and going.

Each node will have the etcd connection values in it's environment:

```js
var Yoda = require('yoda');

var hostname = process.env.ETCD_PORT_4001_TCP_ADDR;
var port = process.env.ETCD_PORT_4001_TCP_PORT;

var yoda = new Yoda(hostname, port);

// we are running in a 'test' stack and we want 'backend' endpoints:
var location = yoda.connect('/test/backend');

location.on('add', function(route, endpoint){
	// here we can connect to our backend worker
})
```

Worker nodes also have the same ability to connect to etcd and react to other worker nodes (or event web nodes) arriving.