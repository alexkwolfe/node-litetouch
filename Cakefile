{spawn, exec} = require 'child_process'
log = console.log

task 'build', ->
  run './node_modules/coffee-script/bin/coffee -o lib -c src'

task 'test', ->
  run './node_modules/.bin/mocha spec/* --compilers coffee:coffee-script/register --reporter spec --colors'

task 'clean', ->
  run 'rm -fr ./lib'

run = (command) ->
  cmd = spawn '/bin/sh', ['-c', command]
  cmd.stdout.on 'data', (data) ->
    process.stdout.write data
  cmd.stderr.on 'data', (data) ->
    process.stderr.write data
  process.on 'SIGHUP', ->
    cmd.kill()
  cmd.on 'exit', (code) ->
    process.exit(code)