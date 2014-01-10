var Parser = require('rdb-tools').Parser,
    parser = new Parser(),
    Writable = require('stream').Writable;

var writable = new Writable({objectMode: true});
writable._write = function(chunk, encoding, cb) {
    console.log(chunk);
    cb();
};

// Deal cleanly with stdout suddenly closing (e.g. if piping through 'head')
process.stdout.on('error', function(err) {
    if (err.code === 'EPIPE') {
        process.exit(0);
    }
})

process.stdin.pipe(parser).pipe(writable);