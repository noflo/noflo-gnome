noflo = require 'noflo'
InBoundPorts = require '../lib/InBoundPorts'
OutBoundPorts = require '../lib/OutBoundPorts'

Clutter = imports.gi.Clutter

class ClutterCoglContext extends noflo.Component
  description: 'Gets the CoglContext attached used by Clutter'
  constructor: ->
    @inPorts = new InBoundPorts
    @inPorts.add 'start',
      datatype: 'bang'
      description: 'Initialize the process'
      required: true

    @outPorts = new OutBoundPorts
    @outPorts.add 'context',
      datatype: 'object'
      required: false
      getValue: () => @getContext()

    @inPorts.start.on 'data', () =>
      return unless @outPorts.context.isAttached()
      @outPorts.context.send(@getContext())
      @outPorts.context.disconnect()


  getContext: () ->
    return Clutter.get_default_backend()

exports.getComponent = -> new ClutterCoglContext
