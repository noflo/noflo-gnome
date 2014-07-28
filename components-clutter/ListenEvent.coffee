noflo = require 'noflo'

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
        event.consumed = false
        @outPorts.event.send event
        @outPorts.event.disconnect()
        return event.consumed

  c.shutdown = () ->
    @updateActor null
  c
