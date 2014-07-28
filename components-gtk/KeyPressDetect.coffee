noflo = require 'noflo'
Gdk = imports.gi.Gdk;

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Detects key presses'

  c.inPorts.add 'event',
    datatype: 'object'
    description: 'Event to process to recognize a swipe gesture'
    process: (event, payload) ->
      return unless event is 'data'
      c.processEvent payload
      return
  c.inPorts.add 'reset',
    datatype: 'bang'
    description: 'Reset processing'
    process: (event, payload) ->
      return unless event is 'disconnect'
      c.reset()
      return

  c.outPorts.add 'processedevent',
    datatype: 'object'
    description: 'Processed events'
  c.outPorts.add 'discardedevent',
    datatype: 'object'
    description: 'Discarded events'
  c.outPorts.add 'keyval',
    datatype: 'string'
    description: 'Key pressed'

  c.processEvent = (event) ->
    switch event.get_event_type()
      when Gdk.EventType.KEY_PRESS
        [s, keyval] = event.get_keyval()
        name = Gdk.keyval_name keyval
        c.outPorts.keyval.send name
        c.outPorts.processedevent.send event
        c.outPorts.keyval.disconnect()
        c.outPorts.processedevent.disconnect()
      when Gdk.EventType.KEY_RELEASE
        c.outPorts.processedevent.send event
        c.outPorts.processedevent.disconnect()
      else
        c.outPorts.discardedevent.send event
        c.outPorts.discardedevent.disconnect()

  c
