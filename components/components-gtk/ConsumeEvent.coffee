noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Consumes a GdkEvent'

  c.inPorts.add 'event',
    datatype: 'object'
    process: (event, payload) ->
      return unless event is 'data'
      payload.consumed = true

  c
