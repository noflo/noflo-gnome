noflo = require 'noflo'
Gtk = imports.gi.Gtk

class Show extends noflo.Component
  description: 'Show a GtkWidget'
  constructor: ->
    @inPorts = new noflo.InPorts
      in:
        datatype: 'object'
        description: ''
        required: true
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'object'
        description: ''
        required: false

    @inPorts.in.on 'data', (widget) =>
      widget.show()
      @outPorts.out.send widget
      @outPorts.out.disconnect()

exports.getComponent = -> new Show
