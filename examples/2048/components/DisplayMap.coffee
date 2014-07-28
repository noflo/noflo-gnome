noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'stage',
    datatype: 'object'
    required: yes
  c.inPorts.add 'map',
    datatype: 'array'
    required: yes

  c.outPorts.add 'map',
    datatype: 'array'

  noflo.helpers.WirePattern c,
    in: 'map'
    params: 'stage'
    out: 'map'
    forwardGroups: true
  , (map, groups, out) ->
    for x in [0..(map.length - 1)]
      for y in [0..(map[0].length - 1)]
        c.params.stage.add_child map[x][y].actor
    c.outPorts.map.send map

  c
