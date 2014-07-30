noflo = require 'noflo'

class Log extends noflo.Component
  description: 'Logs the input on the console'
  constructor: ->
    @inPorts =
      in: new noflo.Port 'all'

    @inPorts.in.on 'data', (data) =>
      log(data)

exports.getComponent = -> new Log
