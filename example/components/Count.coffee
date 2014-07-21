noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'in',
    datatype: 'bang'
    required: yes
  c.inPorts.add 'clear',
    datatype: 'bang'
    required: no
    process: (event, payload) ->
      delete c.value

  c.outPorts.add 'out',
    datatype: 'int'

  noflo.helpers.WirePattern c,
    in: 'in'
    out: 'out'
    forwardGroups: true
  , (data, groups, out) ->
    if c.value?
      c.value += 1
    else
      c.value = 0
    out.send c.value

  c
