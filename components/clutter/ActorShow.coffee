noflo = require 'noflo'

class ActorShow extends noflo.Component
  description: 'Show an actor'
  constructor: ->
    @inPorts =
      actor: new noflo.Port 'object'

    @inPorts.actor.on 'data', (actor) =>
      actor.show()

exports.getComponent = -> new ActorShow
