EventEmitter = require('events').EventEmitter

class Socket extends EventEmitter
  constructor: ->
    @response = null

  write: (data) ->
    @data = data
    @emit('data', "#{@response}\r")

module.exports = Socket