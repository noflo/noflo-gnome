require 'noflo'
Runtime = imports.runtime;

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'in',
    datatype: 'bang'

  c.outPorts.add 'arguments',
    datatype: 'array'
    description: 'Array of command line arguments'

  noflo.helpers.WirePattern c,
    in: 'in'
    out: 'arguments'
    forwardGroups: true
  , (data, groups, out) ->
    out.send Runtime.getArguments()

  c
