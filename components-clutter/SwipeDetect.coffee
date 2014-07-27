noflo = require 'noflo'
Clutter = imports.gi.Clutter;

coordsToDirection = (initial, final) ->
  dx = final.x - initial.x
  dy = final.y - initial.y
  return 'none' if dx == 0 and dx == dy
  if Math.abs(dx) > Math.abs(dy)
    return if dx > 0 then 'right' else 'left'
  else
    return if dy > 0 then 'down' else 'up'
  return 'unknown'

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Detects swipe gestures'

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
  c.outPorts.add 'direction',
    datatype: 'string'
    description: 'Direction of the detected swipe'

  c.processEvent = (event) ->
    switch event.type()
      when Clutter.EventType.BUTTON_PRESS, Clutter.EventType.TOUCH_BEGIN
        coords = event.get_coords()
        @initial =
          x: coords[0]
          y: coords[1]
        c.outPorts.processedevent.send event
        c.outPorts.processedevent.disconnect()
      when Clutter.EventType.BUTTON_RELEASE, Clutter.EventType.TOUCH_END
        return unless @initial
        coords = event.get_coords()
        final =
          x: coords[0]
          y: coords[1]
        val = coordsToDirection @initial, final
        c.outPorts.direction.send val unless val is 'none'
        c.outPorts.processedevent.send event
        c.outPorts.direction.disconnect()
        c.outPorts.processedevent.disconnect()
        @reset()
      else
        c.outPorts.discardedevent.send event
        c.outPorts.discardedevent.disconnect()

  c.reset = () ->
    delete @initial

  c.shutdown = () ->
    @reset()
  c
