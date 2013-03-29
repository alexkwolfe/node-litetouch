EventEmitter = require('events').EventEmitter

class Socket extends EventEmitter
  constructor: ->
    @output = null

  write: (input) ->
    @input = input
    @emit('readable') if @output

  read: ->
    @output if @output

module.exports = Socket