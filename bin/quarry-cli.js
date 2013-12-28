#!/usr/bin/env node

/**
 * Module dependencies.
 */
var version = require(__dirname + '/../package.json').version;
var program = require('commander');
var quarry = require('../src');

program
  .version(version)

program
  .command('build [id] [dir] [buildfolder]')
  .description('generate launch instructions for a stack')
  .action(function(id, dir, buildfolder){

    var builder = quarry.builder({
      id:id,
      dir:dir
    })

    builder.build(buildfolder, function(error, instructions){
      
    })

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