noflo = require 'noflo'
GLib = imports.gi.GLib;
Runtime = imports.runtime;

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Convert a path to a URI'

  c.inPorts.add 'in',
    datatype: 'string'

  c.outPorts.add 'out',
    datatype: 'string'
    description: 'Array of command line arguments'

  noflo.helpers.WirePattern c,
    in: 'in'
    out: 'out'
    forwardGroups: true
  , (data, groups, out) ->
    if data[0] is '/'
      out.send "file://#{data}"
    else
      out.send "file://#{GLib.getenv('PWD')}/#{data}"

  c
