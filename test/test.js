var etcdx = require('../src');
var async = require('async');

describe('etcdx', function(){

	function get_client(opts){
		return new etcdx(opts);
	}

	before(function(done){
		var client = get_client();

		async.forEachSeries(['/folder', '/apples', '/applefolder'], function(folder, nextfolder){
			client.rmdir(folder, function(){
				nextfolder();
			});
		}, done)
	})

	describe('core', function(){
		it('should be an event emitter', function(done) {
			var client = get_client();

			client.on('test', done);
			client.emit('test');
		})	
	})

	
	describe('urls', function(){
		it('should have a baseurl that is correct', function() {
			var client = get_client();

			client.url().should.equal('http://127.0.0.1:4001/v2')
		})

		it('should be configurable and allow the config to change after instantiation', function() {
			var client = get_client({
				port:1234,
				version:1,
				host:'1.2.3.4'
			});

			client.url().should.equal('http://1.2.3.4:1234/v1');

			client.configure({
				port:5678,
				version:2
			})

			client.url().should.equal('http://1.2.3.4:5678/v2');
		})

		it('should append keys onto the url', function() {
			var client = get_client();

			client.url('apple').should.equal('http://127.0.0.1:4001/v2/keys/apple')
			client.url('/apple').should.equal('http://127.0.0.1:4001/v2/keys/apple')
		})

		it('should allow query strings into the url', function() {
			var client = get_client();

			client.url('apple', {
				a:10
			}).should.equal('http://127.0.0.1:4001/v2/keys/apple?a=10')
		})
	})

	describe('values', function (){

		it('should write values', function(done){
			var client = get_client();

			async.series([
				function(next){
					client.set('/apples', 'oranges', function(error, result){
						result.action.should.equal('set');
						result.node.key.should.equal('/apples');
						result.node.value.should.equal('oranges');
						client.get('/apples', function(error, result){
							result.action.should.equal('get');
							result.node.key.should.equal('/apples');
							result.node.value.should.equal('oranges');
							next();
						})
					})		
				},

				function(next){
					client.set('/applefolder/green/red', 'oranges', function(error, result){
						result.action.should.equal('set');
						result.node.key.should.equal('/applefolder/green/red');
						result.node.value.should.equal('oranges');
						client.get('/applefolder/green/red', function(error, result){
							result.action.should.equal('get');
							result.node.key.should.equal('/applefolder/green/red');
							result.node.value.should.equal('oranges');
							next();
						})
					})
				}
			], done)
			
		})

		it('should write a ttl value', function(done){

			this.timeout(2000);

			var client = get_client();

			client.set_ttl('/applefolder/timeout', 'self-destruct', 1, function(error, result){
				result.action.should.equal('set');
				result.node.ttl.should.equal(1);
				setTimeout(function(){
					client.get('/applefolder/timeout', function(error, result){
						result.node.value.should.equal('self-destruct');
					})
				}, 500)
				setTimeout(function(){
					client.get('/applefolder/timeout', function(error, result){
						error.status.should.equal(404);
						done();
					})
				}, 1500)
			})
			
		})

		it('should create and list directories', function(done){
			var client = get_client();

			function mkdir(key, done){
				client.mkdir(key, function(error, result){
					result.action.should.equal('set');
					result.node.key.should.equal(key);
					result.node.dir.should.equal(true);
					done();
				})
			}

			async.forEachSeries(['/folder/a', '/folder/b', '/folder/c', '/folder/b/level2'], mkdir, function(error){
				client.ls('/folder', true, function(error, results){
					results.action.should.equal('get');
					results.node.dir.should.equal(true);
					var nodes = {};
					results.node.nodes.forEach(function(node){
						nodes[node.key] = node;
					})
					nodes['/folder/b'].nodes[0].key.should.equal('/folder/b/level2');
					client.rmdir('/folder', function(){
						client.ls('/folder', function(error, results){
							error.status.should.equal(404);
							done();
						})
					})
				})
			})

		})
		
	})

	describe('watcher', function (){

		it('should watch values', function(done){

			this.timeout(2000);

			var client = get_client();

			var value_history = {};

			function write_value(val){
				client.set('/apples', val);
			}

			client.watch('/apples', function(error, result){
				value_history['val' + result.node.value] = true;
				return true;
			})

			setTimeout(function(){
				[10, 20, 30, 40].forEach(write_value);

				setTimeout(function(){
					value_history['val10'].should.equal(true);
					value_history['val20'].should.equal(true);
					value_history['val30'].should.equal(true);
					value_history['val40'].should.equal(true);
					done();
				}, 1000)
			}, 100)			
		})

	})

})
