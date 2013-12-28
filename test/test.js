var quarry = require('../src');

describe('quarry', function(){

	describe('builder', function(){

		it('should process quarry.yml', function (done) {
	    
	    var builder = quarry.builder({
	    	id:'test',
	    	dir:__dirname
	    })

	    var doc = builder.doc;

	    doc.mongo.type.should.equal('service');
	    doc.mongo.expose[0].should.equal(27017);
	    doc.redis.type.should.equal('service');
	    doc.redis.expose[0].should.equal(6379);
	    doc.app.type.should.equal('worker');
	    doc.app.domains[0].should.equal('app.test.com');
	    done();

	  })

		it('should list the service and worker nodes', function (done) {
	    
	    var builder = quarry.builder({
	    	id:'test',
	    	dir:__dirname
	    })

	    builder.nodes.service.length.should.equal(2);
	    builder.nodes.worker.length.should.equal(3);

	    done();
	    

	  })

	  it('should return quarry launch instructions', function (done) {
	    
	    var builder = quarry.builder({
	    	id:'test',
	    	dir:__dirname
	    })

	    builder.build(function(error, instructions){
	    	var parts = instructions.split("\n");
	    	parts[0].should.equal('quarry service test mongo quarry/mongo 27017')
	    	done();
	    })

	  })

	})

})
