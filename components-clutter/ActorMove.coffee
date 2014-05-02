noflo = require 'noflo'

class ActorMove extends noflo.Component
  description: 'Change the position of a ClutterActor'
  constructor: ->
    @inPorts =
      actor: new noflo.Port 'object'
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'

    @inPorts.actor.on 'data', (actor) =>
      @actor = actor
    @inPorts.actor.on 'disconnect', () =>
      delete @actor

    @inPorts.x.on 'data', (x) =>
      return unless @actor
      @actor.x = x

    @inPorts.y.on 'data', (y) =>
      return unless @actor
      @actor.y = y

exports.getComponent = -> new ActorMove
