noflo = require 'noflo'
GdkPixbuf = imports.gi.GdkPixbuf

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Download a URL'

  c.inPorts.add 'data',
    datatype: 'object'
    description: 'A GByte containing data to be loaded'

  c.outPorts.add 'pixbuf',
    datatype: 'object'
    description: 'A GdkPixbuf loaded with input data'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'data'
    out: 'pixbuf'
    forwardGroups: true
  , (data, groups, out) ->
    try
      loader = new GdkPixbuf.PixbufLoader
      loader.write_bytes data.data
      loader.close()
      out.send loader.get_pixbuf()
    catch e
      c.error e, groups
