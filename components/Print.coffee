noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Prints the input on the console'

  c.inPorts.add 'in',
    datatype: 'string'
    process: (event, payload) ->
      return unless event is 'data'
      print payload
      return

  c
