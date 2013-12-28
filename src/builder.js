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

Builder.prototype.process_node = function(folder, node){
  if(node.container.indexOf('.')==0){

  }

  if(node.expose && node.expose.length>0){
    fs.writeFileSync(folder + '/expose', node.expose.join(" "), 'utf8');  
  }

  if(node.domains && node.domains.length>0){
    fs.writeFileSync(folder + '/domains', node.domains.join(" "), 'utf8');  
  }

  fs.writeFileSync(folder + '/container', node.container, 'utf8');
}

Builder.prototype.build = function(folder, done){
  var self = this;

  var instructions = [];
  
  this.nodes.service.forEach(function(service){
    var service_root = folder + '/service/' + service.name;
    wrench.mkdirSyncRecursive(service_root);
    self.process_node(service_root, service);

    var boot = [
      "quarry",
      "service",
      self.options.id,
      service.name
    ].join(" ")

    instructions.push(boot);
    fs.writeFileSync(service_root + '/boot', boot, 'utf8');

  })

  this.nodes.worker.forEach(function(worker){
    var worker_root = folder + '/worker/' + worker.name;
    wrench.mkdirSyncRecursive(worker_root);
    self.process_node(worker_root, worker);

    var boot = [
      "quarry",
      "worker",
      self.options.id,
      worker.name
    ].join(" ")

    instructions.push(boot);
    fs.writeFileSync(worker_root + '/boot', boot, 'utf8');
  })

  fs.writeFileSync(folder + '/instructions', instructions.join("\n"), 'utf8');

  done && done(null, instructions.join("\n"));
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

  function process_container(node){
    if(node.container.match(/\/Dockerfile/)){
      self.instructions.push({
        type:'build',
        id:self.options.id + '/' + node.name,
        container:node.container
      })

      node.container = self.options.id + '/' + node.name;
    }
  }

  this.nodes.service.forEach(function(service){

    process_container(service);

    self.instructions.push({
      type:'ensure',
      name:self.options.id + '/' + service.name,
      container:service.container,
      expose:service.expose
    })
  })

  this.nodes.worker.forEach(function(worker){

    process_container(worker);

    self.instructions.push({
      type:'deploy',
      name:self.options.id + '/' + worker.name,
      container:worker.container,
      expose:worker.expose,
      domains:worker.domains,
      install:worker.install,
      run:worker.run
    })
  })
}