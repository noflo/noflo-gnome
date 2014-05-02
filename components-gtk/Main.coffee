noflo = require 'noflo'
noflo_gnome = require 'noflo-gnome'
Gtk = imports.gi.Gtk

class Main extends noflo.Component
  description: 'Run the Gtk+ mainloop'
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
      noflo_gnome.replaceMainloop Gtk.main
      @outPorts.out.send true
      @outPorts.out.disconnect()

exports.getComponent = -> new Main
