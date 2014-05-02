noflo = require 'noflo'

class ActorHide extends noflo.Component
  description: 'Hide an actor'
  constructor: ->
    @inPorts =
      actor: new noflo.Port 'object'

    @inPorts.actor.on 'data', (actor) =>
      actor.hide()

exports.getComponent = -> new ActorHide
