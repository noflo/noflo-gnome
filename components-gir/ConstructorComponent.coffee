noflo = require 'noflo'

exports.getComponentForConstructor = (type, cons) ->
  (metadata) ->
    c = new noflo.Component
    c.description = "Create a new #{type} widget instance"
    c.icon = 'desktop'
    c.inPorts.add 'create',
      datatype: 'bang'
      process: (event, payload) ->
        return unless event is 'data'
        try
          instance = new cons
        catch e
          c.error e
          return
        c.outPorts.instance.send instance
        c.outPorts.instance.disconnect()

    c.outPorts.add 'instance',
      datatype: 'object'
      required: no
    c.outPorts.add 'error',
      datatype: 'object'
      required: no
    c
