noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'map',
    datatype: 'array'

  c.outPorts.add 'map',
    datatype: 'array'

  noflo.helpers.WirePattern c,
    in: 'map'
    out: 'map'
    forwardGroups: true
  , (map, groups, out) ->
    while true
      x = Math.round(Math.random() * (map.length - 1))
      y = Math.round(Math.random() * (map[0].length - 1))

      if map[x][y].value == 0
        map[x][y].value = 2
        map[x][y].init = true
        map[x][y].actor.text = "2"
        map[x][y].actor.opacity = 255
        break
    out.send map

  c
