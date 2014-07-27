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
  c.description = 'Listen events on a ClutterActor'

  c.inPorts.add 'actor',
    datatype: 'object'
    description: 'Actor to listen events from'
    process: (event, payload) ->
      return unless event is 'data'
      c.updateActor payload
      return
  c.inPorts.add 'reset',
    datatype: 'bang'
    description: 'Reset processing'
    process: (event, payload) ->
      return unless event is 'disconnect'
      c.updateActor null
      return

  c.outPorts.add 'event',
    datatype: 'object'
    description: 'ClutterEvent from the actor'

  c.updateActor = (actor) ->
    if @actor
      @actor.disconnect @listener
      delete @listener
    @actor = actor
    if @actor
      @listener = @actor.connect 'event', (actor, event) =>
        @outPorts.event.send event
        @outPorts.event.disconnect()

  c.shutdown = () ->
    @updateActor null
  c
