noflo = require 'noflo'
noflo_gnome = require 'noflo-gnome'
Clutter = imports.gi.Clutter

class Main extends noflo.Component
  description: 'Run the Clutter mainloop'
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
      noflo_gnome.replaceMainloop Clutter.main
      @outPorts.out.send true
      @outPorts.out.disconnect()

exports.getComponent = -> new Main
