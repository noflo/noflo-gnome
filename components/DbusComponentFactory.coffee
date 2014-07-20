noflo = require 'noflo'
GLib = imports.gi.GLib
Gio = imports.gi.Gio
Lang = imports.lang
Utils = imports.utils

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

    c.getProxy = () ->
      return null unless @bus and @path
      return @proxy if @proxy
      @proxy = Gio.DBusProxy.new_sync @getConnection(), Gio.DBusProxyFlags.NONE, iface, @bus, @path, iface.name, null

    c.destroyProxy = () ->
      return unless @proxy
      @proxy.disconnect @listener
      delete @listener
      delete @proxy
      return

    c.propertiesChanged = (proxy, propsValues, propsInvalidated) ->
      keyVals = Utils.unpackVariant(propsValues, true);
      ports = []
      for k, v of keyVals
        port = @propertyToPort[k]
        continue unless port
        port.send v
        ports.push port
      for port in ports
        port.disconnect()

    c.updateProxy = () ->
      return unless @bus and @path
      @destroyProxy()
      @listener = @getProxy().connect 'g-properties-changed', Lang.bind(@, @propertiesChanged)
      return

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
        return
    c.inPorts.add 'path',
      datatype: 'string'
      description: 'Path of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.path = payload
        c.updateProxy()
        return

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

    c.getProxy = () ->
      return @proxy if @proxy
      @proxy = Gio.DBusProxy.new_sync @getConnection(), Gio.DBusProxyFlags.NONE, iface, @bus, @path, iface.name, null

    c.destroyProxy = () ->
      return unless @proxy
      delete @proxy
      return

    c.updateProxy = () ->
      return unless @proxy
      delete @proxy
      return

    # Callback from setting value through dbus
    c.propertySet = (proxy, result) ->
      return unless @proxy == proxy
      try
        @proxy.call_finish(result)
      catch e
        @outPorts.error.send e
        @outPorts.error.disconnect()
      return

    # Send property set through dbus
    c.setProperty = (propName, signature, value) ->
      return unless @bus and @path
      variant = new GLib.Variant(signature, value)
      wrappedVariant = new GLib.Variant('(ssv)',  [iface.name, propName, variant])
      @getProxy().call('org.freedesktop.DBus.Properties.Set', wrappedVariant, Gio.DBusCallFlags.NONE, -1, null, Lang.bind(@, @propertySet))
      return

    c.description = "Set properties on #{iface.name}"
    c.icon = 'book'

    c.inPorts.add 'system',
      datatype: 'boolean'
      description: 'Session bus (false), System bus (true)'
      process: (event, payload) ->
        return unless event is 'data'
        c.system = payload
        c.updateProxy()
        return
    c.inPorts.add 'bus',
      datatype: 'string'
      description: 'Bus name of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.bus = payload
        c.updateProxy()
        return
    c.inPorts.add 'path',
      datatype: 'string'
      description: 'Path of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.path = payload
        c.updateProxy()
        return

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
          return
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

    c.destroyProxy = () ->
      return unless @proxy
      delete @proxy
      return

    c.callReply = (proxy, result) ->
      succeeded = false
      try
        outVariant = proxy.call_finish(result);
        succeeded = true;
        ret = outVariant.deep_unpack()
        ports = []
        for i, value of ret
          continue unless @outPortsArray[i]
          @outPortsArray[i].send value
          ports.push @outPortsArray[i]
        for port in ports
          port.disconnect()
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
        return
    c.inPorts.add 'path',
      datatype: 'string'
      description: 'Path of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.path = payload
        c.destroyProxy()
        return
    c.inPorts.add 'call',
      datatype: 'bang'
      description: 'Trigger function call through DBus'
      process: (event, payload) ->
        return unless event is 'data'
        c.call()
        return

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
          return
      return component.inPorts[portName]
    addOutPort = (component, arg) ->
      portName = arg.name.replace(/[^A-Za-z0-9_]/g, '_').toLowerCase()
      component.outPorts.add portName,
        datatype: signatureToDatatype arg.signature
        required: no
      return component.outPorts[portName]

    # Add all ports
    c.inValues = []
    c.inSignature = ''
    c.outPortsArray = []
    if method.in_args and method.in_args.length > 0
      for i in [0..(method.in_args.length - 1)]
        arg = method.in_args[i]
        c.inSignature += arg.signature
        #log "argin #{arg.name}/#{arg.signature} from #{method.name} (#{c.inSignature})"
        addInPort c, arg, i
    if method.out_args and method.out_args.length > 0
      for i in [0..(method.out_args.length - 1)]
        arg = method.out_args[i]
        #log "argout #{arg.name}/#{arg.signature} from #{method.name}"
        c.outPortsArray.push addOutPort(c, arg)
    c


exports.getComponentSignal = (iface, signal) ->
  (metadata) ->
    c = new noflo.Component

    c.dbusIface = iface
    c.dbusSignal = signal

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

    c.destroyProxy = () ->
      return unless @proxy
      @proxy.disconnect @listener
      delete @listener
      delete @proxy
      return

    c.processSignal = (proxy, senderName, signalName, parameters) ->
      return unless signalName == @dbusSignal.name
      args = parameters.deep_unpack()
      ports = []
      for i, arg of args
        port = @outPortsArray[i]
        port.send arg
        ports.push port
      for port in ports
        port.disconnect()

    c.updateProxy = () ->
      @destroyProxy()
      proxy = @getProxy()
      return unless proxy?
      @listener = proxy.connect 'g-signal', @processSignal.bind @
      return

    c.description = "Monitors signal #{signal.name} on #{iface.name}"
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
        return
    c.inPorts.add 'path',
      datatype: 'string'
      description: 'Path of the sender'
      process: (event, payload) ->
        return unless event is 'data'
        c.path = payload
        c.updateProxy()
        return

    # helper functions to add ports
    addOutPort = (component, arg) ->
      portName = arg.name.replace(/[^A-Za-z0-9_]/g, '_').toLowerCase()
      component.outPorts.add portName,
        datatype: signatureToDatatype arg.signature
        required: no
      return component.outPorts[portName]

    # Add all ports
    c.outPortsArray = []
    if signal.args and signal.args.length > 0
      for i in [0..(signal.args.length - 1)]
        arg = signal.args[i]
        #log "signal argout #{arg.name}/#{arg.signature} from #{signal.name}"
        c.outPortsArray.push addOutPort(c, arg)
    c
