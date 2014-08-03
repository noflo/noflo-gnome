noflo = require 'noflo'

Gio = imports.gi.Gio
Lang = imports.lang

class GioStreamClose extends noflo.Component
  description: 'closed a GInputStream/GOutputStream'
  constructor: ->
    super()
    @inPorts =
      stream: new noflo.Port 'object'
    @outPorts =
      closed: new noflo.Port 'object'
      failed: new noflo.Port 'object'

    @inPorts.stream.on 'data', (stream) =>
      @stream = stream

    @inPorts.stream.on 'disconnect', () =>
      return unless @stream
      @stream.close_async(0, null, Lang.bind(this, @closed))

  closed: (stream, res) ->
    port = @outPorts.failed
    try
      port = @outPorts.closed if stream.close_finish(res)
    catch
    finally
      if port.isAttached()
        port.send(stream)
        port.disconnect()

exports.getComponent = -> new GioStreamClose
