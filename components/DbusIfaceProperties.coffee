noflo = require 'noflo'
GLib = imports.gi.GLib
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

exports.getComponentOutputProperties = (iface) ->
  (metadata) ->
    c = new noflo.Component

    c.shutdown = () ->
      @destroyProxy()

    c.getConnection = () ->
      bus = if @system then Gio.BusType.SYSTEM else Gio.BusType.SESSION
      connection = Gio.bus_get_sync bus, null
      return connection

    c.getProxy = () ->
      return null unless @bus and @path
      return @proxy if @proxy
      @proxy = Gio.DBusProxy.new_sync @getConnection(), Gio.DBusProxyFlags.NONE, iface, @bus, @path, iface.name, null

    c.destroyProxy = () ->
      return unless @proxy
      @proxy.disconnect @listener
      delete @listener
      delete @proxy

    c.propertiesChanged = (proxy, propsValues, propsInvalidated) ->
      keyVals = propsValues.deep_unpack()
      ports = []
      for k, v of keyVals
        port = @propertyToPort[k]
        continue unless port
        port.send v.deep_unpack()
        ports.push port
      for port in ports
        port.disconnect()

    c.updateProxy = () ->
      return unless @bus and @path
      @destroyProxy()
      @listener = @getProxy().connect 'g-properties-changed', Lang.bind(@, @propertiesChanged)

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


exports.getComponentInputProperties = (iface) ->
  (metadata) ->
    c = new noflo.Component

    c.shutdown = () ->
      @destroyProxy()

    c.getConnection = () ->
      bus = if @system then Gio.BusType.SYSTEM else Gio.BusType.SESSION
      connection = Gio.bus_get_sync bus, null
      return connection

    c.getProxy = () ->
      return @proxy if @proxy
      @proxy = Gio.DBusProxy.new_sync @getConnection(), Gio.DBusProxyFlags.NONE, iface, @bus, @path, iface.name, null
      return @proxy

    c.destroyProxy = () ->
      return unless @proxy
      delete @proxy

    c.updateProxy = () ->
      return unless @proxy
      delete @proxy

    # Callback from setting value through dbus
    c.propertySet = (proxy, result) ->
      return unless @proxy == proxy
      try
        @proxy.call_finish(result)
      catch e
        @outPorts.error.send e
        @outPorts.error.disconnect()

    # Send property set through dbus
    c.setProperty = (propName, signature, value) ->
      return unless @bus and @path
      variant = new GLib.Variant(signature, value)
      wrappedVariant = new GLib.Variant('(ssv)',  [iface.name, propName, variant])
      @getProxy().call('org.freedesktop.DBus.Properties.Set', wrappedVariant, Gio.DBusCallFlags.NONE, -1, null, Lang.bind(@, @propertySet))

    c.description = "Set properties on #{iface.name}"
    c.icon = 'book'

    c.inPorts.add 'system',
      datatype: 'boolean'
      description: 'Session bus (false), System bus (true)'
      process: (event, payload) ->
        return unless event is 'data'
        c.system = payload
        c.updateProxy()
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

    # helper function to add ports
    addInPort = (component, prop) ->
      portName = prop.name.replace(/[^A-Za-z0-9_]/g, '_').toLowerCase()
      component.inPorts.add portName,
        datatype: signatureToDatatype prop.signature
        required: no
        process: (event, payload) ->
          return unless event is 'data'
          component.setProperty @propName, prop.signature, payload
      component.inPorts[portName].propName = prop.name

    # Add all ports
    for i in [0...(iface.properties.length)]
      prop = iface.properties[i]
      continue unless prop.flags & Gio.DBusPropertyInfoFlags.WRITABLE
      addInPort c, prop
    c


exports.getComponentMethod = (iface, method) ->
  (metadata) ->
    c = new noflo.Component

    c.dbusIface = iface
    c.dbusMethod = method

    c.shutdown = () ->
      @destroyProxy()

    c.getConnection = () ->
      bus = if @system then Gio.BusType.SYSTEM else Gio.BusType.SESSION
      connection = Gio.bus_get_sync bus, null
      return connection

    c.getProxy = () ->
      return null unless @bus and @path
      return @proxy if @proxy
      @proxy = Gio.DBusProxy.new_sync @getConnection(), Gio.DBusProxyFlags.NONE, @dbusIface, @bus, @path, @dbusIface.name, null
      return @proxy

    c.destroyProxy = () ->
      return unless @proxy
      delete @proxy

    c.callReply = (proxy, result) ->
      succeeded = false
      try
        outVariant = proxy.call_finish(result);
        succeeded = true;
        log outVariant.deep_unpack()
      catch e
        @outPorts.error.send e
        @outPorts.error.disconnect()

    c.call = () ->
      inVariant = new GLib.Variant("(#{@inSignature})", @inValues)
      @getProxy().call(method.name, inVariant,  Gio.DBusCallFlags.NONE, -1, null, Lang.bind(@, @callReply))

    c.description = "Call #{method.name} on #{iface.name}"
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
        c.destroyProxy()
    c.inPorts.add 'path',
      datatype: 'string'
      description: 'Path of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.path = payload
        c.destroyProxy()
    c.inPorts.add 'call',
      datatype: 'bang'
      description: 'Trigger function call through DBus'
      process: (event, payload) ->
        return unless event is 'data'
        c.call()

    c.outPorts.add 'error',
      datatype: 'object'

    # helper functions to add ports
    addInPort = (component, arg, position) ->
      portName = arg.name.replace(/[^A-Za-z0-9_]/g, '_').toLowerCase()
      component.inPorts.add portName,
        datatype: signatureToDatatype arg.signature
        required: yes
        process: (event, payload) ->
          return unless event is 'data'
          component.inValues[position] = payload
    addOutPort = (component, arg) ->
      portName = arg.name.replace(/[^A-Za-z0-9_]/g, '_').toLowerCase()
      component.outPorts.add portName,
        datatype: signatureToDatatype arg.signature
        required: yes
      component.outArgumentsToPort[arg.name] = component.outPorts[portName]

    # Add all ports
    c.inValues = []
    c.outArgumentsToPort = []
    c.inSignature = ''
    if method.in_args and method.in_args.length > 0
      for i in [0..(method.in_args.length - 1)]
        arg = method.in_args[i]
        c.inSignature += arg.signature
        addInPort c, arg
    if method.out_args and method.out_args.length > 0
      for i in [0..(method.out_args.length - 1)]
        arg = method.out_args[i]
        addOutPort c, arg
    c
