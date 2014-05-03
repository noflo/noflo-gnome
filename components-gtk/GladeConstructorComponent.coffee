noflo = require 'noflo'
Gtk = imports.gi.Gtk

exports.getComponentForFile = (file) ->

  (metadata) ->
    c = new noflo.Component

    builder = new Gtk.Builder
    objects = []
    error = null
    try
      Gtk.init null, null
      builder.add_from_file(file.get_path())
      objects = builder.get_objects()
    catch e
      error = e

    c.description = "Widgets from #{file.get_basename()}"

    c.icon = 'book'
    c.inPorts.add 'start',
      datatype: 'bang'
      process: (event, payload) ->
        return unless event is 'data'
        if error?
          c.outPorts.error.send error
          c.outPorts.error.disconnect()
        else
          for portName, port  of c.outPorts.ports
            port.send port.object
            port.disconnect()

    c.outPorts.add 'error',
      datatype: 'object'
      required: no

    for obj in objects
      name = obj.get_name().replace /[^A-Za-z0-9_]/g, ''
      c.outPorts.add name,
        datatype: 'object'
        required: no
      c.outPorts[name].object = obj
    c
