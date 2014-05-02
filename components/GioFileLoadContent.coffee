noflo = require 'noflo'

Gio = imports.gi.Gio

class GioFileLoadContent extends noflo.Component
  description: 'Loads the content of a file'
  constructor: ->
    @inPorts =
      filename: new noflo.Port 'string'
    @outPorts =
      content: new noflo.ArrayPort 'string'

    @inPorts.filename.on 'data', (filename) =>
      return unless @outPorts.content.isAttached()
      file = Gio.File.new_for_path(filename)
      [status, content, size, etag] = file.load_contents(null)
      @outPorts.content.send('' + content)
      @outPorts.content.disconnect()


exports.getComponent = -> new GioFileLoadContent
