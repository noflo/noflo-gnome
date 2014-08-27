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
    async: true
  , (data, groups, out, callback) ->
    return unless out.isAttached()
    unless data?
      c.error new Error 'Invalid filename', groups
      return
    file = Gio.File.new_for_uri data
    file.load_contents_async null, (src, res) ->
      try
        [status, content, etag] = file.load_contents_finish res
        packet =
          data: content
          length: content.length
          toString: () ->
            "[C Buffer - length=#{@length}]" # prevent warnings
      catch e
        c.error e, groups
        do callback
        return
      out.send packet
      do callback
      return

  c
