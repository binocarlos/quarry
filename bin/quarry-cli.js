#!/usr/bin/env node

/**
 * Module dependencies.
 */
var version = require(__dirname + '/../package.json').version;
var program = require('commander');

program
  .option('-d, --dir <string>', 'the folder the quarry.yml file lives in', '.')
  .version(version)

program
  .command('build')
  .description('build an app folder into quarry launch file')
  .action(function(){

    console.log('-------------------------------------------');
    console.dir(program.dir);

  })

// run help if the command is not known or they just type 'digger'
program
  .command('*')
  .action(function(command){

    var spawn = require('child_process').spawn;

    spawn('quarry-cli', ['--help'], {
      stdio: 'inherit'
    });

  });

if(process.argv.length<=2){
  process.argv.push(['--help']);
}

program.parse(process.argv);