noflo = require 'noflo'
noflo_gnome = require 'noflo-gnome'
Gtk = imports.gi.Gtk

class Quit extends noflo.Component
  description: 'Quit the Gtk+ mainloop'
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
      Gtk.main_quit()
      @outPorts.out.send true
      @outPorts.out.disconnect()

exports.getComponent = -> new Quit
