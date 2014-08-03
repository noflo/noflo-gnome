noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'map',
    datatype: 'array'
    process: (event, map) ->
      return unless map
      for x in [0..(map.length - 1)]
        for y in [0..(map[0].length - 1)]
          map[x][y].actor.destroy()
      return

  c
