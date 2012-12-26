assert = require('chai').assert
LiteTouch = require('../litetouch')
Socket = require('./socket')

describe 'Callback', ->
  litetouch = null
  socket = null

  beforeEach ->
    socket = new Socket()
    litetouch = new LiteTouch(socket)

  it 'should callback on acknowledge', (done) ->
    socket.response = 'R,RSACK,SIEVN'
    litetouch.send 'SIEVN', '7', -> done()

