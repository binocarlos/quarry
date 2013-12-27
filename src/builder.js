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
var util = require('util');

function Builder(options){
  EventEmitter.call(this);
  this.options = options || {};
  if(!fs.existsSync(this.options.dir)){
  	throw new Error(this.options.dir + ' does not exist');
  }

  if(!fs.existsSync(this.filepath())){
  	throw new Error(this.filepath() + ' does not exist');
  }

  this.nodes = {
    service:[],
    worker:[],
    web:[],
    config:[]
  };

  this.process(yaml.safeLoad(fs.readFileSync(this.filepath(), 'utf8')))
}

util.inherits(Builder, EventEmitter);

module.exports = Builder;

Builder.prototype.filepath = function(){
	return this.options.dir + '/quarry.yml';
}

Builder.prototype.process = function(doc){
  var self = this;
  this.doc = doc;

  Object.keys(this.doc).forEach(function(key){
    var obj = doc[key];
    obj.name = key;

    self.nodes[obj.type].push(obj);
  })
}