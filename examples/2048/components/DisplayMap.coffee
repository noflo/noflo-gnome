noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'stage',
    datatype: 'object'
  c.inPorts.add 'map',
    datatype: 'array'

  c.outPorts.add 'map',
    datatype: 'array'

  noflo.helpers.WirePattern c,
    in: ['map', 'stage']
    out: 'map'
    forwardGroups: true
  , (data, groups, out) ->
    for x in [0..(data.map.length - 1)]
      for y in [0..(data.map[0].length - 1)]
        data.stage.add_child data.map[x][y].actor
    c.outPorts.map.send data.map

  c
