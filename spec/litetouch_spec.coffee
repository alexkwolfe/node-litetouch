assert = require('chai').assert
LiteTouch = require('../src/litetouch')
Socket = require('./socket')

describe 'LiteTouch', ->
  litetouch = null
  socket = null

  beforeEach ->
    socket = new Socket()
    litetouch = new LiteTouch(socket)

  it 'should set internal event notify', (done) ->
    socket.output = 'R,RSACK,SIEVN\r'
    litetouch.internalEventNotify 7, ->
      assert.equal socket.input, 'R,SIEVN,7\r'
      done()

  it 'should set station notify', (done) ->
    socket.output = 'R,RSACK,SSTNN\r'
    litetouch.stationNotify 12, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,SSTNN,012,3\r'
      done()

  it 'should set module notify', (done) ->
    socket.output = 'R,RSACK,SMODN\r'
    litetouch.moduleNotify 32, 0, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,SMODN,032,0\r'
      done()

  it 'should get clock', (done) ->
    socket.output = 'R,RQRES,DGCLK,20121225120155\r'
    litetouch.getClock (err, date) ->
      return done(err) if err
      expected = new Date('2012', '11', '25', '12', '01', '55', '00')
      assert.equal expected.getTime(), date.getTime()
      done()

  it 'should set clock', (done) ->
    date = new Date('2012', '11', '25', '12', '01', '55', '00')
    socket.output = 'R,RQRES,DSCLK\r'
    litetouch.setClock date, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,DSCLK,20121225120155\r'
      done()

  it 'should set LED on', (done) ->
    socket.output = 'R,RCACK,CLDON\r'
    litetouch.setLedOn 12, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CLDON,012,3\r'
      done()

  it 'should set LED off', (done) ->
    socket.output = 'R,RCACK,CLDOF\r'
    litetouch.setLedOff 12, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CLDOF,012,3\r'
      done()

  it 'should get sunrise', (done) ->
    socket.output = 'R,RQRES,CGTSR,Sunrise at [0725] Astro Time is [1738] Local Time is [1738]\r'
    litetouch.getSunrise (err, msg) ->
      return done(err) if err
      assert.equal socket.input, 'R,CGTSR\r'
      assert.equal msg.sunrise.hour, '07'
      assert.equal msg.sunrise.minute, '25'
      assert.equal msg.astroTime.hour, '17'
      assert.equal msg.astroTime.minute, '38'
      assert.equal msg.localTime.hour, '17'
      assert.equal msg.localTime.minute, '38'
      done()

  it 'should get sunset', (done) ->
    socket.output = 'R,RQRES,CGTSS,Sunset at [0725] Astro Time is [1738] Local Time is [1738]\r'
    litetouch.getSunset (err, msg) ->
      return done(err) if err
      assert.equal socket.input, 'R,CGTSS\r'
      assert.equal msg.sunset.hour, '07'
      assert.equal msg.sunset.minute, '25'
      assert.equal msg.astroTime.hour, '17'
      assert.equal msg.astroTime.minute, '38'
      assert.equal msg.localTime.hour, '17'
      assert.equal msg.localTime.minute, '38'
      done()

  it 'should get module levels', (done) ->
    socket.output = 'R,RQRES,DGMLV,0003,02,35,100,33,25,100,100,0,15\r'
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

  it 'should press switch', (done) ->
    socket.output = 'R,RCACK,CPRSW\r'
    litetouch.pressSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CPRSW,0053\r'
      done()

  it 'should hold switch', (done) ->
    socket.output = 'R,RCACK,CHDSW\r'
    litetouch.holdSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CHDSW,0053\r'
      done()

  it 'should release switch', (done) ->
    socket.output = 'R,RCACK,CRLSW\r'
    litetouch.releaseSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CRLSW,0053\r'
      done()

  it 'should toggle switch', (done) ->
    socket.output = 'R,RCACK,CTGSW\r'
    litetouch.toggleSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CTGSW,0053\r'
      done()

  it 'should press hold switch', (done) ->
    socket.output = 'R,RCACK,CPHSW\r'
    litetouch.pressHoldSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CPHSW,0053\r'
      done()

  it 'should toggle loads on', (done) ->
    socket.output = 'R,RCACK,CTLON\r'
    litetouch.toggleLoadsOn 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CTLON,001\r'
      done()

  it 'should toggle loads off', (done) ->
    socket.output = 'R,RCACK,CTLOF\r'
    litetouch.toggleLoadsOff 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CTLOF,001\r'
      done()

  it 'should start ramp', (done) ->
    socket.output = 'R,RCACK,CSTRP\r'
    litetouch.startRamp 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CSTRP,001\r'
      done()

  it 'should stop ramp', (done) ->
    socket.output = 'R,RCACK,CSPRP\r'
    litetouch.stopRamp 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CSPRP,001\r'
      done()

  it 'should start ramp to min', (done) ->
    socket.output = 'R,RCACK,CSRMN\r'
    litetouch.startRampToMin 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CSRMN,001\r'
      done()

  it 'should start ramp to max', (done) ->
    socket.output = 'R,RCACK,CSRMX\r'
    litetouch.startRampToMax 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CSRMX,001\r'
      done()

  it 'should lock loads', (done) ->
    socket.output = 'R,RCACK,CLCKL\r'
    litetouch.lockLoads 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CLCKL,001\r'
      done()

  it 'should unlock loads', (done) ->
    socket.output = 'R,RCACK,CUNLL\r'
    litetouch.unlockLoads 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CUNLL,001\r'
      done()

  it 'should lock switch', (done) ->
    socket.output = 'R,RCACK,CLCKS\r'
    litetouch.lockSwitch 3, 5, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CLCKS,0035\r'
      done()

  it 'should unlock switch', (done) ->
    socket.output = 'R,RCACK,CUNLS\r'
    litetouch.unlockSwitch 3, 5, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CUNLS,0035\r'
      done()

  it 'should lock timer', (done) ->
    socket.output = 'R,RCACK,CLCKT\r'
    litetouch.lockTimer 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CLCKT,001\r'
      done()

  it 'should unlock timer', (done) ->
    socket.output = 'R,RCACK,CUNLT\r'
    litetouch.unlockTimer 1, (err) ->
      return done(err) if err
      assert.equal socket.input, 'R,CUNLT,001\r'
      done()

  it 'should emit switch press', (done) ->
    litetouch.on 'press:12,3', done
    socket.output = 'R,REVNT,SWP,00C3\r'
    socket.emit('readable')

  it 'should emit general switch press', (done) ->
    litetouch.on 'press', (station, button) ->
      assert.equal 12, station
      assert.equal 3, button
      done()
    socket.output = 'R,REVNT,SWP,00C3\r'
    socket.emit('readable')

  it 'should emit switch release', (done) ->
    litetouch.on 'release:12,3', done
    socket.output = 'R,REVNT,SWR,00C3\r'
    socket.emit('readable')

  it 'should emit general switch release', (done) ->
    litetouch.on 'release', (station, button) ->
      assert.equal 12, station
      assert.equal 3, button
      done()
    socket.output = 'R,REVNT,SWR,00C3\r'
    socket.emit('readable')

  it 'should emit switch hold', (done) ->
    litetouch.on 'hold:12,3', done
    socket.output = 'R,REVNT,SWH,00C3\r'
    socket.emit('readable')

  it 'should emit general switch press', (done) ->
    litetouch.on 'hold', (station, button) ->
      assert.equal 12, station
      assert.equal 3, button
      done()
    socket.output = 'R,REVNT,SWH,00C3\r'
    socket.emit('readable')

  it 'should emit led update', (done) ->
    litetouch.on 'led:10', (states) ->
      expected = [false, false, true, false, true, true, false, false, false, false, false, false, false, false, false, false]
      assert.deepEqual expected, states
      done()
    socket.output = 'R,RLEDU,010,0010110000000000\r'
    socket.emit('readable')

  it 'should emit module update', (done) ->
    litetouch.on 'loads:32', (levels) ->
      expected = [90, null, 0, null, 50, 0, 30, null]
      assert.deepEqual expected, levels
      done()
    socket.output = 'R,RMODU,0032,FF,90,-1,0,-1,50,0,30,-1\r'
    socket.emit('readable')

  it 'should handle null on read', ->
    socket.output = null
    socket.emit('readable')
