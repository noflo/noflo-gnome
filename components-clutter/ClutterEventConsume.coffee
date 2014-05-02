noflo = require 'noflo'

Clutter = imports.gi.Clutter

class ClutterEventConsume extends noflo.Component
  description: 'Consumes an event'
  constructor: ->
    @inPorts =
      event: new noflo.Port 'object'

    @inPorts.event.on 'data', (event) =>
      event.consumed = true

exports.getComponent = -> new ClutterEventConsume
