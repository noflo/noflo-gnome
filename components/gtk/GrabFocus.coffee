noflo = require 'noflo'
Clutter = imports.gi.Clutter;

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Grab focus'

  c.inPorts.add 'in',
    datatype: 'object'
    description: 'Widget to grab focus'

  c.outPorts.add 'out',
    datatype: 'object'

  noflo.helpers.MapComponent c,
    (data, groups, out) ->
      data.grab_default()
      data.grab_focus()
      out.send data
  ,
    inPort: 'in'
    outPort: 'out'

  c
