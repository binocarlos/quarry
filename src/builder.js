/*

  (The MIT License)

  Copyright (C) 2005-2013 Kai Davenport

  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */

/*
  Module dependencies.
*/

var EventEmitter = require('events').EventEmitter;
var fs = require('fs');
var yaml = require('js-yaml');
var wrench = require('wrench');
var path = require('path');
var util = require('util');

function Builder(options){
  EventEmitter.call(this);

  this.options = options || {};

  if(!this.options.id){
    throw new Error('an id is required for the stack builder');
  }
  
  if(!fs.existsSync(this.options.dir)){
  	throw new Error(this.options.dir + ' does not exist');
  }

  if(!fs.existsSync(this.filepath())){
  	throw new Error(this.filepath() + ' does not exist');
  }

  this.nodes = {
    service:[],
    worker:[]
  };

  this.instructions = [];

  this.process(yaml.safeLoad(fs.readFileSync(this.filepath(), 'utf8')));
}

util.inherits(Builder, EventEmitter);

module.exports = Builder;

Builder.prototype.filepath = function(){
	return this.options.dir + '/quarry.yml';
}

Builder.prototype.build_node = function(folder, node){
  var self = this;
  var id = self.options.id + "/" + node.name;

  if(fs.existsSync(path.normalize(self.options.dir + '/' + node.container + '/Dockerfile'))){
    var node_src_folder = path.normalize(self.options.dir + '/' + node.container);

    wrench.copyDirSyncRecursive(node_src_folder, folder + '/build');
    node.container = id;
  }
  else if(node.install){
    wrench.copyDirSyncRecursive(self.options.dir, folder + '/build');

    var Dockerfile = [
      'FROM ' + (node.container || 'quarry/node'),
      'ADD . /srv/quarryapp'
    ]

    if(typeof(node.install)==='string'){
      node.install = [node.install];
    }

    var installer = node.install.map(function(cmd){
      return 'RUN cd /srv/quarryapp && ' + cmd;
    }).join("\n")

    Dockerfile.push(installer);
    
    Dockerfile.push("ENTRYPOINT cd /srv/quarryapp && " + node.run);
    Dockerfile = Dockerfile.join("\n");

    fs.writeFileSync(folder + '/build/Dockerfile', Dockerfile, 'utf8');
    node.container = id;
  }
  else if(node.run){
    wrench.copyDirSyncRecursive(self.options.dir, folder + '/build');

    if(typeof(node.run)!=='string'){
      node.run = node.run.join(' && ');
    }

    var Dockerfile = [
      'FROM ' + (node.container || 'quarry/node'),
      'ADD . /srv/quarryapp'
    ]
    
    Dockerfile.push("ENTRYPOINT cd /srv/quarryapp && " + node.run);
    Dockerfile = Dockerfile.join("\n");

    fs.writeFileSync(folder + '/build/Dockerfile', Dockerfile, 'utf8');
    node.container = id;
  }

  if(node.domains){
    if(typeof(node.domains)==='string' && fs.existsSync(path.normalize(self.options.dir + '/' + node.domains))){
      var domaintxt = fs.readFileSync(path.normalize(self.options.dir + '/' + node.domains), 'utf8');
      node.domains = domaintxt.split("\n");
    }
    if(!node.expose){
      node.expose = [];
    }
    var existing = node.expose.filter(function(port){
      return port==80;
    })
    if(existing.length<=0){
      node.expose.push(80);
    }
    fs.writeFileSync(folder + '/domains', node.domains.join(" "), 'utf8');  
  }

  if(node.expose && node.expose.length>0){
    if(typeof(node.expose)==='string'){
      node.expose = [node.expose];
    }
    fs.writeFileSync(folder + '/expose', node.expose.join(" "), 'utf8');  
  }

  if(node.volumes && node.volumes.length>0){
    if(typeof(node.volumes)==='string'){
      node.volumes = [node.volumes];
    }
    fs.writeFileSync(folder + '/volumes', node.volumes.join(" "), 'utf8');  
  }

  if(node.document_root){
    fs.writeFileSync(folder + '/document_root', node.document_root, 'utf8');   
  }

  if(node.container){
    fs.writeFileSync(folder + '/container', node.container, 'utf8');  
  }

  if(node.global){
    fs.writeFileSync(folder + '/global', node.global, 'utf8');  
  }

  fs.writeFileSync(folder + '/node.json', JSON.stringify(node), 'utf8');

  
  
}

Builder.prototype.build = function(folder, done){
  var self = this;

  this.nodes.service.forEach(function(service){
    var service_root = folder + '/service/' + service.name;
    wrench.mkdirSyncRecursive(service_root);
    self.build_node(service_root, service);
  })

  this.nodes.worker.forEach(function(worker){
    var worker_root = folder + '/worker/' + worker.name;
    wrench.mkdirSyncRecursive(worker_root);
    self.build_node(worker_root, worker);
  })

  done && done();
}

Builder.prototype.process = function(doc){
  var self = this;
  this.doc = doc;

  Object.keys(this.doc).forEach(function(key){
    var obj = doc[key];
    obj.name = key;

    if(self.nodes[obj.type]){
      self.nodes[obj.type].push(obj);  
    }
  })
}