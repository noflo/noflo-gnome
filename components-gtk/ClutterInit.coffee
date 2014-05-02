noflo = require 'noflo'
GtkClutter = imports.gi.GtkClutter

class ClutterInit extends noflo.Component
  description: 'Init the GtkClutter framework'
  constructor: ->
    @inPorts = new noflo.InPorts
      in:
        datatype: 'bang'
        description: ''
        required: true
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'bang'
        description: ''
        required: false

    @inPorts.in.on 'data', (data) =>
      GtkClutter.init null, null
      @outPorts.out.send true
      @outPorts.out.disconnect()

exports.getComponent = -> new ClutterInit
