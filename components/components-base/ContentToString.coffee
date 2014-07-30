noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'in',
    datatype: 'object'
    description: 'A content object (C buffer)'

  c.outPorts.add 'out',
    datatype: 'string'
    description: 'A string'

  noflo.helpers.WirePattern c,
    in: 'in'
    out: 'out'
    forwardGroups: true
  , (data, groups, out) ->
    out.send '' + data.data

  c
