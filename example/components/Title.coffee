noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'album',
    datatype: 'string'
    required: yes
  c.inPorts.add 'artist',
    datatype: 'string'
    required: yes
  c.inPorts.add 'title',
    datatype: 'string'
    required: yes

  c.outPorts.add 'out',
    datatype: 'string'

  noflo.helpers.WirePattern c,
    in: [ 'artist', 'album', 'title' ]
    out: 'out'
    forwardGroups: true
  , (data, groups, out) ->
    if data.title? and data.artist? and data.album?
      out.send "#{data.title} by #{data.artist} from #{data.album}"
    else if data.title? and data.artist?
      out.send "#{data.title} by #{data.artist}"
    else
      out.send ""

  c
