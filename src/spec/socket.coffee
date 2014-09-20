EventEmitter = require('events').EventEmitter
Duplex = require('stream').Duplex

class Socket extends Duplex
  constructor: ->
    @output = null
    super

  write: (input) ->
    @input = input
    @emit('readable') if @output

  read: ->
    try
      @output
    finally
      @output = null

module.exports = Socket