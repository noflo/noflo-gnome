noflo = require 'noflo'
Gtk = imports.gi.Gtk

class Show extends noflo.Component
  description: 'Show a GtkWidget'
  icon: 'eye'
  constructor: ->
    @inPorts = new noflo.InPorts
      in:
        datatype: 'object'
        description: ''
        required: yes
      all:
        datatype: 'boolean'
        description: ''
        required: no
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'object'
        description: ''
        required: no

    @all = false
    @inPorts.all.on 'data', (@all) =>
    @inPorts.in.on 'data', (widget) =>
      if @all
        widget.show_all()
      else
        widget.show()
      @outPorts.out.send widget
      @outPorts.out.disconnect()

exports.getComponent = -> new Show
