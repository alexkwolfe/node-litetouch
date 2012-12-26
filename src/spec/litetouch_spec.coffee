assert = require('chai').assert
LiteTouch = require('../litetouch')
Socket = require('./socket')

describe 'LiteTouch', ->
  litetouch = null
  socket = null

  beforeEach ->
    socket = new Socket()
    litetouch = new LiteTouch(socket)

  it 'should set internal event notify', (done) ->
    socket.response = 'R,RSACK,SIEVN'
    litetouch.internalEventNotify 7, ->
      assert.equal socket.data, 'R,SIEVN,7\r'
      done()

  it 'should set station notify', (done) ->
    socket.response = 'R,RSACK,SSTNN'
    litetouch.stationNotify 12, 3, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,SSTNN,012,3\r'
      done()

  it 'should set module notify', (done) ->
    socket.response = 'R,RSACK,SMODN'
    litetouch.moduleNotify 32, 0, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,SMODN,032,0\r'
      done()

  it 'should get clock', (done) ->
    socket.response = 'R,RQRES,DGCLK,20121225120155'
    litetouch.getClock (err, date) ->
      return done(err) if err
      expected = new Date('2012', '11', '25', '12', '01', '55', '00')
      assert.equal expected.getTime(), date.getTime()
      done()

  it 'should set clock', (done) ->
    date = new Date('2012', '11', '25', '12', '01', '55', '00')
    socket.response = 'R,RQRES,DSCLK'
    litetouch.setClock date, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,DSCLK,20121225120155\r'
      done()

  it 'should get sunrise', (done) ->
    socket.response = 'R,RQRES,CGTSR,Sunrise at [0725] Astro Time is [1738] Local Time is [1738]'
    litetouch.getSunrise (err, msg) ->
      return done(err) if err
      assert.equal socket.data, 'R,CGTSR\r'
      assert.equal msg.sunrise.hour, '07'
      assert.equal msg.sunrise.minute, '25'
      assert.equal msg.astroTime.hour, '17'
      assert.equal msg.astroTime.minute, '38'
      assert.equal msg.localTime.hour, '17'
      assert.equal msg.localTime.minute, '38'
      done()

  it 'should get sunset', (done) ->
    socket.response = 'R,RQRES,CGTSS,Sunset at [0725] Astro Time is [1738] Local Time is [1738]'
    litetouch.getSunset (err, msg) ->
      return done(err) if err
      assert.equal socket.data, 'R,CGTSS\r'
      assert.equal msg.sunset.hour, '07'
      assert.equal msg.sunset.minute, '25'
      assert.equal msg.astroTime.hour, '17'
      assert.equal msg.astroTime.minute, '38'
      assert.equal msg.localTime.hour, '17'
      assert.equal msg.localTime.minute, '38'
      done()

  it 'should get module levels', (done) ->
    socket.response = 'R,RQRES,DGMLV,0003,02,35,100,33,25,100,100,0,15'
    litetouch.getModuleLevels 1, (err, levels) ->
      return done(err) if err
      expected = [
        { on: true, level: 2 }
        { on: true, level: 35 },
        { on: false, level: 100 },
        { on: false, level: 33 },
        { on: false, level: 25 },
        { on: false, level: 100 },
        { on: false, level: 100 },
        { on: false, level: 0 },
        { on: false, level: 15 }
      ]
      assert.deepEqual expected, levels
      done()