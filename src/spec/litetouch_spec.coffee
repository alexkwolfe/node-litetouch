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

  it 'should press switch', (done) ->
    socket.response = 'R,RCACK,CPRSW'
    litetouch.pressSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CPRSW,0053\r'
      done()

  it 'should hold switch', (done) ->
    socket.response = 'R,RCACK,CHDSW'
    litetouch.holdSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CHDSW,0053\r'
      done()

  it 'should release switch', (done) ->
    socket.response = 'R,RCACK,CRLSW'
    litetouch.releaseSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CRLSW,0053\r'
      done()

  it 'should toggle switch', (done) ->
    socket.response = 'R,RCACK,CTGSW'
    litetouch.toggleSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CTGSW,0053\r'
      done()

  it 'should press hold switch', (done) ->
    socket.response = 'R,RCACK,CPHSW'
    litetouch.pressHoldSwitch 5, 3, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CPHSW,0053\r'
      done()

  it 'should toggle loads on', (done) ->
    socket.response = 'R,RCACK,CTLON'
    litetouch.toggleLoadsOn 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CTLON,001\r'
      done()

  it 'should toggle loads off', (done) ->
    socket.response = 'R,RCACK,CTLOF'
    litetouch.toggleLoadsOff 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CTLOF,001\r'
      done()

  it 'should start ramp', (done) ->
    socket.response = 'R,RCACK,CSTRP'
    litetouch.startRamp 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CSTRP,001\r'
      done()

  it 'should stop ramp', (done) ->
    socket.response = 'R,RCACK,CSPRP'
    litetouch.stopRamp 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CSPRP,001\r'
      done()

  it 'should start ramp to min', (done) ->
    socket.response = 'R,RCACK,CSRMN'
    litetouch.startRampToMin 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CSRMN,001\r'
      done()

  it 'should start ramp to max', (done) ->
    socket.response = 'R,RCACK,CSRMX'
    litetouch.startRampToMax 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CSRMX,001\r'
      done()

  it 'should lock loads', (done) ->
    socket.response = 'R,RCACK,CLCKL'
    litetouch.lockLoads 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CLCKL,001\r'
      done()

  it 'should unlock loads', (done) ->
    socket.response = 'R,RCACK,CUNLL'
    litetouch.unlockLoads 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CUNLL,001\r'
      done()

  it 'should lock switch', (done) ->
    socket.response = 'R,RCACK,CLCKS'
    litetouch.lockSwitch 3, 5, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CLCKS,0035\r'
      done()

  it 'should unlock switch', (done) ->
    socket.response = 'R,RCACK,CUNLS'
    litetouch.unlockSwitch 3, 5, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CUNLS,0035\r'
      done()

  it 'should lock timer', (done) ->
    socket.response = 'R,RCACK,CLCKT'
    litetouch.lockTimer 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CLCKT,001\r'
      done()

  it 'should unlock timer', (done) ->
    socket.response = 'R,RCACK,CUNLT'
    litetouch.unlockTimer 1, (err) ->
      return done(err) if err
      assert.equal socket.data, 'R,CUNLT,001\r'
      done()

  it 'should emit switch press', (done) ->
    litetouch.on 'press:12,3', done
    socket.emit('data', 'R,REVNT,SWP,00C3\r')

  it 'should emit switch release', (done) ->
    litetouch.on 'release:12,3', done
    socket.emit('data', 'R,REVNT,SWR,00C3\r')

  it 'should emit switch hold', (done) ->
    litetouch.on 'hold:12,3', done
    socket.emit('data', 'R,REVNT,SWH,00C3\r')

  it 'should emit led update', (done) ->
    litetouch.on 'led:10', (states) ->
      expected = [false, false, true, false, true, true, false, false, false, false, false, false, false, false, false, false]
      assert.deepEqual expected, states
      done()
    socket.emit('data', 'R,RLEDU,010,0010110000000000\r ')

  it 'should emit module update', (done) ->
    litetouch.on 'loads:32', (levels) ->
      expected = [90, null, 0, null, 50, 0, 30, null]
      assert.deepEqual expected, levels
      done()
    socket.emit('data', 'R,RMODU,0032,FF,90,-1,0,-1,50,0,30,-1\r')