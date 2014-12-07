EventEmitter = require('events').EventEmitter
split = require('split')
Socket = require('net').Socket

acknowlegements = [ 'RSACK', 'RCACK', 'RQRES' ]

hex = (num) ->
  pad num.toString(16).toUpperCase()

pad = (num) ->
  num = num.toString()
  while (num.length < 3)
    num = "0#{num}"
  num


class LiteTouch extends EventEmitter
  constructor: (@socket) ->
    @setup()

  setup: =>
    @socket.pipe(split('\r')).on 'data', (line) =>
      @handleMessage(line.toString('ascii'))


  ###
  Internal: A message has been received and must be handled. Messages acknowledging a command or responding to
  a query are emitted with the command as the event name and the additional payload as the event contents. Messages
  announching an event notification, LED update, or module update are also emitted.

  msg: String message sent by the LiteTouch controller.
  ###
  handleMessage: (msg) ->
    # R,RSACK,SIEVN
    parts = msg.split(',')
    parts.shift() # R
    type = parts.shift() # ack (RSACK, RCACK, RQRES), event (REVNT), module update (RMODU), led update (RLEDU)
    cmd = parts.shift() # cmd
    if type in acknowlegements
      @emit(cmd, parts)
    else if type == 'REVNT'
      @handleEventNotification(cmd, parts)
    else if type == 'RLEDU'
      @handleLEDUpdateNotification(cmd, parts)
    else if type == 'RMODU'
      @handleModuleUpdateNotification(cmd, parts)

  ###
  Internal: An event notfication has been sent by the LiteTouch controller. Convert the notification into
  an emitted event.

  Switch notifications result in a press, release, or hold event for the station and switch. Switch numbers
  are 1-based, so the first switch is numbered 1, the second is numbered 2, and so forth.

  Example node.js event names for "event notifications":

    press:2,5   => switch #5 on station #2 was pressed
    release:2,5 => switch #5 on station #2 was released
    hold:3,1    => switch #1 on station #2 was held
  ###
  handleEventNotification: (cmd, parts) ->
    if cmd in ['SWP', 'SWR', 'SWH'] # switch press, hold, release
      cmd = if cmd == 'SWP'
        'press'
      else if cmd == 'SWR'
        'release'
      else if cmd == 'SWH'
        'hold'
      station = parseInt(parts[0].substr(0, 3), 16)
      button = parseInt(parts[0].substr(3, 1), 10)
      @emit(cmd, station, button)
      @emit("#{cmd}:#{station},#{button}")
    else if cmd in ['TMB', 'TME']
      @emit("timer:#{parts[0]}")
      @emit('timer', parts[0])
    else if cmd == 'USR'
      @emit("user:#{parts[0]}")
      @emit('user', parts[0])


  ###
  Internal: An LED update notification has been sent by the LiteTouch controller. Convert the notification
  into an emitted event.

  LED update notifications for a station result in an led event for the station with an Array of Booleans describing
  the whether the LED of each switch is on.

  Example node.js events for LED notifications:

    led:5, [false,true,false,false,true,false,false,false,false,false,false,false,false,false,false] 
      => LEDs on station 5 were updated. LEDs on switch 2 and 5 are on. 
    
    led:1, [true,true,false,false,false,false,false,false,false,false,false,false,false,false,false]
      => LEDs on station 1 were updated. LEDS on switch 1 and 2 are on.

  ###
  handleLEDUpdateNotification: (cmd, parts) ->
    station = parseInt(cmd, 10)
    bitmap = parts.shift().split('').map (bit) -> bit == '1'
    @emit("led:#{station}", bitmap)
    @emit('led', station, bitmap)


  ###
  Internal: A module update notification has been sent by the LiteTouch controller. Convert the notification
  into an emitted event.

  Module update notification indicate that loads have changed levels (lights were dimmed, turned on or off, etc).
  These notifications for a module result in a loads event for the module with an Array of Integers describing
  the current percentage level of loads attached to the module.

  Loads that have not changed levels are represented in the Array with a null value.

  Example node.js event for a module update:

    loads:5, [0,100,30,null,10,null,30,null]
      => Load state has chnaged on module 5. Load 1 is off. Load 2, 3, 5, and 6 are at 100%, 30%, 10% and 30% respectively.
         Load 4, 6, and 8 did not change levels.

  ###
  handleModuleUpdateNotification: (cmd, parts) ->
    module = parseInt(cmd, 10)
    # according to the LiteTouch RTC protocol doc, the "map" field (loads that changed) is not implemented
    changed = parseInt(parts.shift(), 16).toString(2).split('')
    changed = changed.map (bit) -> bit == '1'
    levels = parts.map (level) ->
      if level == '-1'
        null
      else
        parseInt(level, 10)
    @emit("loads:#{module}", levels)
    @emit('loads', module, levels)


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
    out = ['R', cmd].concat(args).join(',')
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
    return callback(new Error 'level must be >= 0 and <= 7') unless level >= 0 and level <= 7
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
    return callback(new Error 'level must be >= 0 and <= 3') unless level >= 0 and level <= 4
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
    return callback(new Error 'level must be >= 0 and <= 1') unless level >= 0 and level <= 1
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
      month = parseInt(date.substr(4, 2), 10) - 1
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

  module: integer module address to query
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
        level: parseInt(level, 10)
      callback null, levels


  ###
  Public: Generates a switch press.

  station: Integer station address
  switch: Integer switch number (one-based numbered left to right on the switch face)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  pressSwitch: (station, swtch, callback) ->
    @_commandSwitch('CPRSW', station, swtch, callback)


  ###
  Public: Generates a switch hold.

  station: Integer station address
  switch: Integer switch number (one-based numbered left to right on the switch face)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  holdSwitch: (station, swtch, callback) ->
    @_commandSwitch('CHDSW', station, swtch, callback)


  ###
  Public: Generates a switch release.

  station: Integer station address
  switch: Integer switch number (one-based numbered left to right on the switch face)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  releaseSwitch: (station, swtch, callback) ->
    @_commandSwitch('CRLSW', station, swtch, callback)


  ###
  Public: Generates a switch press followed by a switch release.

  station: Integer station address
  switch: Integer switch number (one-based numbered left to right on the switch face)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  toggleSwitch: (station, swtch, callback) ->
    @_commandSwitch('CTGSW', station, swtch, callback)


  ###
  Public: Generates a switch press then 0.4 seconds later a hold event.

  station: Integer station address
  switch: Integer switch number (one-based numbered left to right on the switch face)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  pressHoldSwitch: (station, swtch, callback) ->
    @_commandSwitch('CPHSW', station, swtch, callback)


  ###
  Public: Toggles the loads in the specified load group. If the specified group consists of multiple loads at
  indeterminate states, all loads in the group will first be turned on. The next Toggle Loads On command will turn
  the loads off.

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  toggleLoadsOn: (loadGroup, callback) ->
    @send 'CTLON', pad(loadGroup), callback


  ###
  Public: Toggles the loads in the specified load group off. If the specified group consists of multiple loads
  at indeterminate states, all loads in the group will first be turned off. The next ToggleLoadsOff command will turn
  the loads on.

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  toggleLoadsOff: (loadGroup, callback) ->
    @send 'CTLOF', pad(loadGroup), callback


  ###
  Public: Starts ramping the loads in the specified load group.

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  startRamp: (loadGroup, callback) ->
    @send 'CSTRP', pad(loadGroup), callback


  ###
  Public: Stops ramping the loads in the specified load group and leaves them on at the present levels.

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  stopRamp: (loadGroup, callback) ->
    @send 'CSPRP', pad(loadGroup), callback


  ###
  Public: Starts ramping the loads in the specified load group down to the min level

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  startRampToMin: (loadGroup, callback) ->
    @send 'CSRMN', pad(loadGroup), callback


  ###
  Public: Starts ramping the loads in the specified load group up to the max level

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  startRampToMax: (loadGroup, callback) ->
    @send 'CSRMX', pad(loadGroup), callback


  ###
  Public: Locks the loads in the specified load group. This makes this load group inoperable from any
  source until it is unlocked.

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  lockLoads: (loadGroup, callback) ->
    @send 'CLCKL', pad(loadGroup), callback


  ###
  Public: Unlocks the loads in the specified load group. This releases control of the load group, making it
  operable from all sources

  loadGroup: The load group number
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  unlockLoads: (loadGroup, callback) ->
    @send 'CUNLL', pad(loadGroup), callback

  ###
  Public: Locks the specified switch making it inoperable to press, hold, or release commands until unlocked.

  station: Integer station address
  switch: Integer switch number (one-based numbered left to right on the switch face)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  lockSwitch: (station, swtch, callback) ->
    @_commandSwitch 'CLCKS', station, swtch, callback


  ###
  Public: Unlocks the specified switch.

  station: Integer station address
  switch: Integer switch number (one-based numbered left to right on the switch face)
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  unlockSwitch: (station, swtch, callback) ->
    @_commandSwitch 'CUNLS', station, swtch, callback


  ###
  Public: Locks the timer making it inoperable until unlocked.

  timer: the timer ID
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  lockTimer: (timer, callback) ->
    @send 'CLCKT', pad(timer), callback


  ###
  Public: Unlocks the specified timer.

  timer: the timer ID
  callback: function invoked when LiteTouch acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  unlockTimer: (timer, callback) ->
    @send 'CUNLT', pad(timer), callback


  ###
  Internal: Send a switch command.
  ###
  _commandSwitch: (cmd, station, swtch, callback) ->
    swtch = parseInt(swtch, 10) + 1
    return callback(new Error 'switch must be >= 1 and <= 8') unless swtch >= 1 and swtch <= 8
    @send cmd, "#{pad(station)}#{swtch - 1}", callback


  ###
  Public: Connect to the LiteTouch controller.

  ip: String IP address of controller
  port: Integer TCP port of controller (optional, defaults to 10001)
  callback: invoked once the connection has been established (optional)
  ###
  @connect: (args...) ->
    callback = args.pop() if typeof args[args.length - 1] == 'function'
    ip = args.shift()
    port = args.shift() ? 10001

    socket = new Socket(type: 'tcp4')
    lt = new LiteTouch(socket)
    socket.connect(port, ip, callback)
    lt


module.exports = LiteTouch

