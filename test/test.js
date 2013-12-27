var quarry = require('../src');

describe('quarry', function(){

	describe('builder', function(){

		it('should process quarry.yml', function (done) {
	    
	    var builder = quarry.builder({
	    	dir:__dirname
	    })

	    var doc = builder.doc;

	    doc.mongo.type.should.equal('service');
	    doc.mongo.expose[0].should.equal(27017);
	    doc.redis.type.should.equal('service');
	    doc.redis.expose[0].should.equal(6379);
	    doc.app.type.should.equal('web');
	    doc.app.domains[0].should.equal('app.test.com');
	    done();

	  })

	})

})
