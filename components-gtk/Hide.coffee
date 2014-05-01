noflo = require 'noflo'
Gtk = imports.gi.Gtk

class Hide extends noflo.Component
  description: 'Hide a GtkWidget'
  icon: 'eye-slash'
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
      widget.hide()
      @outPorts.out.send widget
      @outPorts.out.disconnect()

exports.getComponent = -> new Hide
