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
    data = "#{data.title} by #{data.artist} from #{data.album}"
    out.send data

  c
