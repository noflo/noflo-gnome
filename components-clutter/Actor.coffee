noflo = require 'noflo'

class Actor extends noflo.Component
  description: 'Find an actor using a name'
  constructor: ->
    @inPorts =
      name: new noflo.Port 'string'

    @outPorts =
      actor: new noflo.ArrayPort 'object'

    @Clutter = imports.gi.Clutter
    @stageManager = @Clutter.StageManager.get_default()
    @stage = @stageManager.list_stages()[0]

    @inPorts.name.on 'data', (name) =>
      ret = @searchActor(name, @stage)
      return unless ret
      @outPorts.actor.send ret

  searchActor: (name, actor) =>
    return actor if actor.name == name
    children = actor.get_children()
    for child in children
      ret = @searchActor(name, child)
      return ret if ret != null
    return null

exports.getComponent = -> new Actor
