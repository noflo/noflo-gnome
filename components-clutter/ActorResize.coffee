noflo = require 'noflo'

class ActorResize extends noflo.Component
  description: 'Change the size of a ClutterActor'
  constructor: ->
    @inPorts =
      actor: new noflo.Port 'object'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'

    @inPorts.actor.on 'data', (actor) =>
      @actor = actor
    @inPorts.actor.on 'disconnect', () =>
      delete @actor

    @inPorts.width.on 'data', (width) =>
      return unless @actor
      @actor.set_width(width)

    @inPorts.height.on 'data', (height) =>
      return unless @actor
      @actor.set_height(height)

exports.getComponent = -> new ActorResize
