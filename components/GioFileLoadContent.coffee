noflo = require 'noflo'

Gio = imports.gi.Gio

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Loads the content of a file'

  c.inPorts.add 'uri',
    datatype: 'string'

  c.outPorts.add 'content',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'uri'
    out: 'content'
    forwardGroups: true
  , (data, groups, out) ->
    return unless out.isAttached()
    try
      file = Gio.File.new_for_uri data
      [status, content, etag] = file.load_contents null
      log "content type: #{typeof content}"
      content.toString = -> ""
      out.send content
    catch e
      c.error e, groups
