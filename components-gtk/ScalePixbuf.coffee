noflo = require 'noflo'
GdkPixbuf = imports.gi.GdkPixbuf

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Download a URL'

  c.inPorts.add 'pixbuf',
    datatype: 'object'
    description: 'A GdkPixbuf to scale'
  c.inPorts.add 'width',
    datatype: 'int'
    description: 'Width to scale to'
    required: yes
  c.inPorts.add 'height',
    datatype: 'int'
    description: 'Height to scale to'
    required: yes

  c.outPorts.add 'pixbuf',
    datatype: 'object'
    description: 'A new GdkPixbuf'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'pixbuf'
    params: ['width', 'height']
    out: 'pixbuf'
    forwardGroups: true
  , (pixbuf, groups, out) ->
    try
      pix = pixbuf.scale_simple c.params.width, c.params.height, GdkPixbuf.InterpType.BILINEAR
    catch e
      c.error e, groups
      return
    out.send pix
    return
