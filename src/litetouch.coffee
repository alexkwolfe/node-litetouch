BufferStream = require('bufferstream')
EventEmitter = require('events').EventEmitter
Socket = require('net').Socket

ack = [ 'RSACK', 'RCACK', 'RQRES' ]

hex = (num) ->
  pad num.toString(16).toUpperCase()

pad = (num) ->
  num = num.toString()
  while (num.length < 3)
    num = "0#{num}"
  num


class LiteTouch extends EventEmitter
  constructor: (@socket) ->
    @buffer = new BufferStream(encoding: 'utf8', size: 'flexible')
    @buffer.split '\r', (message) =>
      @handleMessage(message.toString('ascii'))
    @socket.on('data', @handleData)

  handleData: (data) =>
    @buffer.write(data.toString('ascii'))

  handleMessage: (msg) ->
    # R,RSACK,SIEVN
    parts = msg.split(',')
    parts.shift() # R
    type = parts.shift() # ack (RSACK, RCACK, RQRES), event (REVNT), module update (RMODU), led update (RLEDU)
    cmd = parts.shift() # cmd
    @emit(cmd, parts)

  ###
  Internal: Send a command to the LiteTouch controller.

  cmd: String command to send (i.e. SIEVN)
  args: list of arguments
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  send: (cmd, args...) ->
    callback =
      if typeof args[args.length - 1] == 'function'
        args.pop()
    @once cmd, (msg) -> callback(null, msg) if callback
    out = "R,#{cmd}"
    out = "#{out},#{args.join(',')}" if args.length > 0
    @socket.write("#{out}\r")


  ###
  Public: Enable notification of events such as combinations, timers, and button presses, LED updates, Module Updates, etc.
  These settings are mutually exclusive – i.e. you can’t have both 3 and 5.

  level:  0 - Turn off notification
          1 - Enable Internal (User (Combination and Startup) and Timer Event) notification
          2 - Enable Internal, Switch, and LED Update notification (Maintain compatibility.)
          3 - Enable Switch (Press / Hold / Release) notification
          4 - Enable LED Update notification
          5 - Enable Module Update notification
          6 - Reserved
          7 - Enable all implemented notifications (Combination/Timer, Trigger, LED, Module, etc.)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  internalEventNotify: (level, callback) ->
    return callback(new Error 'level must be >=0 and <= 7') unless level >= 0 and level <= 7
    @send('SIEVN', level, callback)


  ###
  Public: Enable notification of station events and/or LED updates for a station. This does not enable notification
  of combinations and timers.

  station: Integer station address
  level:   0 - Turn off notification
           1 - Enable Switch press/hold/release notification
           2 - Enable LED update notification
           3 - Enable both Switch press/hold/release and LED update notification
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  stationNotify: (station, level, callback) ->
    return callback(new Error 'level must be >=0 and <= 3') unless level >= 0 and level <= 4
    @send('SSTNN', pad(station), level, callback)


  ###
  Public: Enable notification of state or level change events for a module.

  module: Integer module address
  level: 0 - Turn off notification
         1 - Enable Load State and Level notification
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  moduleNotify: (module, level, callback) ->
    return callback(new Error 'level must be >=0 and <= 1') unless level >= 0 and level <= 1
    @send('SMODN', pad(module), level, callback)


  ###
  Public: Requests the date-time.

  callback: function invoked with a single parameter containing the clock's Date

  Returns true if command is sent, otherwise false.
  ###
  getClock: (callback) ->
    @send 'DGCLK', (err, msg) ->
      return callback(err) if err
      date = msg[0]
      year = date.substr(0, 4)
      month = parseInt(date.substr(4, 2)) - 1
      day = date.substr(6, 2)
      hour = date.substr(8, 2)
      minute = date.substr(10, 2)
      second = date.substr(12, 2)
      callback(null, new Date(year, month, day, hour, minute, second, '00'))

  ###
  Public: Sets the clock with the specified date-time.

  date: Date used to set the clock
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  setClock: (date, callback) ->
    year = date.getFullYear()
    month = "0#{date.getMonth() + 1}".slice(-2)
    day = "0#{date.getDate()}".slice(-2)
    hour = "0#{date.getHours()}".slice(-2)
    minute = "0#{date.getMinutes()}".slice(-2)
    second = "0#{date.getSeconds()}".slice(-2)
    @send('DSCLK', "#{year}#{month}#{day}#{hour}#{minute}#{second}", callback)


  ###
  Public: Returns the time sunrise will occur for this day.

  callback: function invoked two parameters - err if an error occured while making the call,
            an object describing the hour and minute of sunrise.

  Returns true if command is sent, otherwise false.
  ###
  sunriseRegex = /Sunrise at \[(\d{2})(\d{2})\]/
  astroTimeRegex = /Astro Time is \[(\d{2})(\d{2})\]/
  localTimeRegex = /Local Time is \[(\d{2})(\d{2})\]/
  getSunrise: (callback) ->
    @send 'CGTSR', (err, msg) ->
      return callback(err) if err
      #R,RQRES,CGTSR,Sunrise at [HHMM] Astro Time is [HHMM] Local Time is [HHMM]
      msg = msg.toString()
      sunrise = {}
      sunriseMatch = msg.match(sunriseRegex)
      if sunriseMatch
        sunrise.sunrise = hour: sunriseMatch[1], minute: sunriseMatch[2]
      astroMatch = msg.match(astroTimeRegex)
      if astroMatch
        sunrise.astroTime = hour: astroMatch[1], minute: astroMatch[2]
      localMatch = msg.match(localTimeRegex)
      if localMatch
        sunrise.localTime = hour: localMatch[1], minute: localMatch[2]
      if sunrise.length < 3
        callback(new Error('could not parse response'))
      else
        callback(null, sunrise)

  ###
  Public: Returns the time sunset will occur for this day.

  callback: function invoked two parameters - err if an error occured while making the call,
            an object describing the hour and minute of sunset.

  Returns true if command is sent, otherwise false.
  ###
  sunsetRegex = /Sunset at \[(\d{2})(\d{2})\]/
  getSunset: (callback) ->
    @send 'CGTSS', (err, msg) ->
      return callback(err) if err
      # R,RQRES,CGTSS,Sunset at [HHMM] Astro Time is [HHMM] Local Time is [HHMM]
      msg = msg.toString()
      sunset = {}
      sunsetMatch = msg.match(sunsetRegex)
      if sunsetMatch
        sunset.sunset = hour: sunsetMatch[1], minute: sunsetMatch[2]
      astroMatch = msg.match(astroTimeRegex)
      if astroMatch
        sunset.astroTime = hour: astroMatch[1], minute: astroMatch[2]
      localMatch = msg.match(localTimeRegex)
      if localMatch
        sunset.localTime = hour: localMatch[1], minute: localMatch[2]
      if sunset.length < 3
        callback(new Error('could not parse response'))
      else
        callback(null, sunset)

  ###
  Public: Returns the levels of all loads on a module.

  module: integer module number to query
  callback: function invoked with two parameters - err if an error occurred while
            making the call, an array of objects describing the levels of each load

  Returns true if command is sent, otherwise false.
  ###
  getModuleLevels: (module, callback) ->
    @send 'DGMLV', hex(module), (err, msg) ->
      return callback(err) if err
      # R,RQRES,DGMLV,0003,02,35,100,33,25,100,100,0,15
      states = parseInt(msg.shift(), 16).toString(2).split('')
      levels = for level, i in msg
        on: states[i] == '1'
        level: parseInt(level)
      callback null, levels

  ###
  Public: Connect to the LiteTouch controller.
  ###
  @create: (ip, port = 10001) ->
    socket = new Socket(fd: 'tcp4')
    lt = new LiteTouch(socket)
    socket.connect(port, ip)
    lt


module.exports = LiteTouch

