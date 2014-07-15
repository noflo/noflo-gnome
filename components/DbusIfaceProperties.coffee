noflo = require 'noflo'
Gio = imports.gi.Gio
Lang = imports.lang

signatureToDatatype = (signature) ->
  switch signature[0]
    when 'y', 'n', 'q', 'i', 'u', 'x', 't'
      return 'integer'
    when 'd'
      return 'number'
    when 's'
      return 'string'
    when 'a'
      return 'array'
    else
      return 'string'

exports.getComponentForOutputProperties = (iface) ->
  (metadata) ->
    c = new noflo.Component

    c.shutdown = () ->
      @stopListener()

    c.getConnection = () ->
      bus = if @system then Gio.BusType.SYSTEM else Gio.BusType.SESSION
      connection = Gio.bus_get_sync bus, null
      return connection

    c.getProxy = () ->
      return @proxy if @proxy
      @proxy = Gio.DBusProxy.new_sync @getConnection(), Gio.DBusProxyFlags.NONE, iface, @bus, @path, iface.name, null

    c.signal = (proxy, propsValues, propsInvalidated) ->
      keyVals = propsValues.deep_unpack()
      ports = []
      for k, v of keyVals
        port = @propertyToPort[k]
        continue unless port
        port.send v.deep_unpack()
        ports.push port
      for port in ports
        port.disconnect()

    c.removeProxy = () ->
      return unless @listener
      @getProxy().disconnect @listener
      delete @listener
      delete @proxy

    c.updateProxy = () ->
      return unless @bus and @path
      @removeProxy() if @listener
      @listener = @getProxy().connect 'g-properties-changed', Lang.bind(@, @signal)

    c.description = "Monitors properties from #{iface.name}"
    c.icon = 'book'

    c.inPorts.add 'system',
      datatype: 'boolean'
      description: 'Session bus (false), System bus (true)'
    c.inPorts.add 'bus',
      datatype: 'string'
      description: 'Bus name of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.bus = payload
        c.updateProxy()
    c.inPorts.add 'path',
      datatype: 'string'
      description: 'Path of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.path = payload
        c.updateProxy()

    # helper function to add ports
    addOutPort = (component, prop) ->
      portName = prop.name.replace(/[^A-Za-z0-9_]/g, '_').toLowerCase()
      component.outPorts.add portName,
        datatype: signatureToDatatype prop.signature
        required: no
      return component.outPorts[portName]

    # Add all ports
    c.propertyToPort = {}
    for i in [0...(iface.properties.length)]
      prop = iface.properties[i]
      continue unless prop.flags & Gio.DBusPropertyInfoFlags.READABLE
      c.propertyToPort[prop.name] = addOutPort c, prop
    c


exports.getComponentForInputProperties = (iface) ->
  (metadata) ->
    c = new noflo.Component

    c.shutdown = () ->
      @stopListener()

    c.getConnection = () ->
      bus = if @system then Gio.BusType.SYSTEM else Gio.BusType.SESSION
      connection = Gio.bus_get_sync bus, null
      return connection

    c.getProxy = () ->
      return @proxy if @proxy
      @proxy = Gio.DBusProxy.new_sync @getConnection(), Gio.DBusProxyFlags.NONE, iface, @bus, @path, iface.name, null

    c.signal = (proxy, propsValues, propsInvalidated) ->
      keyVals = propsValues.deep_unpack()
      ports = []
      for k, v of keyVals
        port = @propertyToPort[k]
        continue unless port
        port.send v.deep_unpack()
        ports.push port
      for port in ports
        port.disconnect()

    c.removeProxy = () ->
      return unless @listener
      @getProxy().disconnect @listener
      delete @listener
      delete @proxy

    c.updateProxy = () ->
      return unless @bus and @path
      @removeProxy() if @listener
      @listener = @getProxy().connect 'g-properties-changed', Lang.bind(@, @signal)
      log "subscribed : #{@listener} |#{@sender}| |#{@path}|"

    c.description = "Monitors properties a #{iface.name} object"
    c.icon = 'book'

    c.inPorts.add 'system',
      datatype: 'boolean'
      description: 'Session bus (false), System bus (true)'
    c.inPorts.add 'bus',
      datatype: 'string'
      description: 'Bus name of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.bus = payload
        c.updateProxy()
    c.inPorts.add 'path',
      datatype: 'string'
      description: 'Path of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.path = payload
        c.updateProxy()

    c.outPorts.add 'error',
      datatype: 'object'
      required: no

    # helper function to add ports
    addInPort = (component, name, property) ->
      component.outPorts.add name,
        datatype: 'object'
        required: no
      return component.outPorts[name]

    # Add all ports
    c.propertyToPort = {}
    for i in [0...(iface.properties.length)]
      prop = iface.properties[i]
      filteredName = prop.name.replace(/[^A-Za-z0-9_]/g, '_').toLowerCase()
      log "#{prop.name} -> #{filteredName} "
      c.propertyToPort[prop.name] = addOutPort c, filteredName
    c
