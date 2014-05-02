noflo = require 'noflo'

Gio = imports.gi.Gio

class GioFileWrite extends noflo.Component
  description: 'Monitors a file for changes'
  constructor: ->
    @inPorts =
      filename: new noflo.Port 'string'
      content: new noflo.Port 'string'

    @inPorts.filename.on 'data', (filename) =>
      @filename = filename

    @inPorts.content.on 'connect', () =>
      return unless @filename
      file = Gio.File.new_for_path(@filename)
      try
        @outputStream = file.create(Gio.FileCreateFlags.REPLACE_DESTINATION, null)
      catch ex
        @outputStream = file.replace('', false, Gio.FileCreateFlags.REPLACE_DESTINATION, null)

    @inPorts.content.on 'data', (data) =>
      return unless @outputStream
      @outputStream.write_all(data, null)

    @inPorts.content.on 'disconnect', () =>
      return unless @outputStream
      @outputStream.close(null)
      @outputStream = null

  shutdown: ->
    if @outputStream
      @outputStream.close()
      @outputStream = null

exports.getComponent = -> new GioFileWrite
