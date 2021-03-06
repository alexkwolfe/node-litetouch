A driver for the LiteTouch lighting control Real Time Control protocol.

[![Build Status](https://secure.travis-ci.org/alexkwolfe/node-litetouch.png)](http://travis-ci.org/alexkwolfe/node-litetouch)

## Usage

Call the connect function to connect with the LiteTouch controller. After the connection has been established,
proceed by interacting with the controller.

```javascript
var LiteTouch = require('litetouch');
var litetouch = LiteTouch.connect('192.168.1.5', 10001, function() {
  // connected to controller

  // listen for a switch press
  litetouch.on('press:1,5', function() {
    console.log('Switch 5 on station 1 has been pressed');
  });

  // press switch 5 on station 1
  litetouch.pressSwitch(1, 5);
});
```

You may also provide a duplex stream to the LiteTouch constructor directly.

```javascript
var LiteTouch = require('litetouch'),
    net = require('net');

var socket = net.createConnection({ ip: '192.168.1.5', port: 10001 })
var litetouch = new LiteTouch(socket);
```


## Events

Events are emitted when the LiteTouch controller sends notifications of state change. Before any notifications are sent
by the controller, the client must use the `internalEventNotify` function to instruct the controller to send them. To turn
on all events, call `internalEventNotify(7)`.

### Switch Press, Hold and Release

Clients may register a listener function to be called when any switch is pressed, held or released. The event name
describes the particulars of the event in the following format: `<event type>:<station address>,<switch number>`.

Example:

```javascript
litetouch.internalEventNotify(3); // can use 2 or 7 instead

// listen for specific button events
litetouch.on('press:3,5', function() {
  console.log('Switch 5 on station 3 has been pressed');
});
litetouch.on('release:3,5', function() {
  console.log('Switch 5 on station 3 has been released');
});
litetouch.on('hold:1,2', function() {
  console.log('Switch 2 on station 1 is being held');
});

// listen to all button events, for every station and switch
litetouch.on('press', function(station, switch) {
  console.log('Switch ' + switch + ' on station ' + station + ' has been pressed');
});
litetouch.on('release', function(station, switch) {
  console.log('Switch ' + switch + ' on station ' + station + ' has been released');
});
litetouch.on('hold', function(station, switch) {
  console.log('Switch ' + switch + ' on station ' + station + ' has been held');
});
```

### Timer and User Events

Clients may register a listener function to be called when a timer or user event occurs.

Example:

```javascript
litetouch.internalEventNotify(1); // can use 2 or 7 instead

// listen to specific timer and user events
litetouch.on('timer:1', function() {
  console.log('Timer 1 fired');
});
litetouch.on('user:3', function() {
  console.log('User event 3 fired');
});

// listen to all timer and user events
litetouch.on('timer', function(id) {
  console.log('Timer ' + id + ' fired');
});
litetouch.on('user', function(id) {
  console.log('User event ' + id + ' fired');
});
```

### LED Update Events

LED Update events occur when LEDs on a switch station change. Clients may register a listener function to be called
when the LED state changes.

Example:

```javascript
litetouch.internalEventNotify(4); // can use 2 or 7 instead

// listen to LED events for a particular station
litetouch.on('led:2', function(stateArray) {
  console.log('The LEDs on station 2 were updated');
  stateArray.forEach(function(state, i) {
    var switchNumber = i + 1;
    console.log('LED ' + switchNumber + ' is now ' + (state ? 'on' : 'off'));
  });
});

// listen to LED events for all stations
litetouch.on('led', function(station, stateArray) {
  console.log('The LEDs on station ' + station + ' were updated');
});
```

### Module Update Events

Module Update events occur when lighting loads on a LiteTouch module are changed. This happens when loads are dimmed,
brightened, turned on or turned off.

Clients may register a listener function to be called when loads change on a module.

Example:

```javascript
litetouch.internalEventNotify(5); // can use 2 or 7 instead

// listen to module update events for a particular module
litetouch.on('loads:2', function(levelArray) {
  console.log('The loads on module 2 were changed');
  levelArray.forEach(function(level, i) {
    var loadNumber = i + 1;
    console.log('Load ' + loadNumber + (level ? ' is now at ' + level '%' : 'was not changed'))
  });
});

// listen to module update events for all modules
litetouch.on('loads', function(module, levelArray) {
  console.log('The loads on module ' + module + ' were changed');
});
```

## Contributing

Pull requests are welcome.

 * Fork this repo.
 * `git checkout -B yourbranch`
 * Make your changes.
 * Open a pull request between your branch and master.