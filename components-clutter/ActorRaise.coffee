noflo = require 'noflo'

class ActorRaise extends noflo.Component
  description: 'Raise a ClutterActor'
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.ArrayPort 'object'

    @inPorts.in.on 'data', (actor) =>
      parent = actor.get_parent()
      parent.set_child_above_sibling(actor, null) if parent
      @outPorts.out.send(actor) if @outPorts.out.isAttached()

exports.getComponent = -> new ActorRaise
