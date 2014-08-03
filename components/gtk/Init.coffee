noflo = require 'noflo'
Gtk = imports.gi.Gtk

class Init extends noflo.Component
  description: 'Init the Gtk+ framework'
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
      Gtk.init null, null
      @outPorts.out.send true
      @outPorts.out.disconnect()

exports.getComponent = -> new Init
