noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'map',
    datatype: 'array'
    process: (event, payload) ->
      return unless event is 'data'
      log "print!"
      for y in [0..(payload[0].length - 1)]
        s = ''
        for x in [0..(payload.length - 1)]
          s += "\t#{payload[x][y].value}"
        print s
      print '==============='
      return

  c
