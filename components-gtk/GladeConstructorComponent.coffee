noflo = require 'noflo'
Gtk = imports.gi.Gtk

exports.getComponentForFile = (file, additionals) ->

  (metadata) ->
    c = new noflo.Component

    c.shutdown = () ->
      @started = false

    builder = new Gtk.Builder
    objects = {}
    error = null
    try
      Gtk.init null, null
      builder.add_from_file(file.get_path())
      for object in builder.get_objects()
        try
          name = object.get_name()
          continue if /^_.*$/.test name
          objects[name] = object
        catch e
      if additionals
        for objectName in additionals
          object = builder.get_object(objectName)
          objects[objectName] = object if object
    catch e
      log "Cannot load #{file.get_path()} : #{e.message}"
      error = e

    c.description = "Widgets from #{file.get_basename()}"

    c.icon = 'book'
    c.inPorts.add 'start',
      datatype: 'bang'
      process: (event, payload) ->
        return unless event is 'data'
        c.started = true
        if error?
          c.outPorts.error.send error
          c.outPorts.error.disconnect()
        else
          ports = []
          for portName, port  of c.outPorts.ports
            continue if portName is 'error'
            #log "Sending #{port.object} on #{portName}"
            port.send port.object
            ports.push port
          for port in ports
            port.disconnect()
        return

    c.outPorts.add 'error',
      datatype: 'object'
      required: no

    # helper function to add ports
    addOutPort = (component, name, object) ->
      component.outPorts.add name,
        datatype: 'object'
        required: no
      component.outPorts[name].object = object
      component.outPorts[name].on 'attach', (socket) ->
        return unless component.started
        socket.send object
        socket.disconnect()
        return

    # Add all ports
    for name, obj of objects
      filteredName = name.replace /[^A-Za-z0-9_]/g, '_'
      addOutPort c, filteredName, obj
    c
