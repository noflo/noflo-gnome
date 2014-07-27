noflo = require 'noflo'
Clutter = imports.gi.Clutter

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'create',
    datatype: 'bang'
  c.inPorts.add 'width',
    datatype: 'int'
  c.inPorts.add 'height',
    datatype: 'int'

  c.outPorts.add 'map',
    datatype: 'array'

  noflo.helpers.WirePattern c,
    in: 'create'
    params: ['width', 'height']
    out: 'map'
    forwardGroups: true
  , (data, groups, out) ->
    map = []
    for i in [0..(c.params.width - 1)]
      map.push []
      for j in [0..(c.params.height - 1)]
        el =
          value: 0
          lastSquash: 0
          actor: new Clutter.Actor
            opacity: 255
          text: new Clutter.Text
            text: "0"
            opacity: 255
            justify: true
        el.actor.add_child el.text
        el.actor.layout_manager = new Clutter.BinLayout
          x_align: 0.5
          y_align: 0.5
        map[i].push el




    out.send map
