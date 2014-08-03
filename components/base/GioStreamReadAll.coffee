noflo = require 'noflo'

Gio = imports.gi.Gio
Lang = imports.lang

class GioStreamReadAll extends noflo.Component
  description: 'read all data coming from an GInputStream'
  constructor: ->
    super()
    @inPorts =
      stream: new noflo.Port 'object'
    @outPorts =
      content: new noflo.ArrayPort 'string'
      done: new noflo.ArrayPort 'object'

    @inPorts.stream.on 'connect', () =>
      return unless @stream
      @cancellable.cancel()
      @stream = null

    @inPorts.stream.on 'data', (stream) =>
      @stream = stream

    @inPorts.stream.on 'disconnect', () =>
      return unless @stream
      @cancellable = new Gio.Cancellable();
      @stream.read_bytes_async(1024, 0, @cancellable, Lang.bind(this, @read_cb))

  read_cb: (stream, res) ->
    try
      bytes = stream.read_bytes_finish(res)
      if bytes == null || bytes.get_size() == 0
        @outPorts.content.disconnect() if @outPorts.content.isConnected()
        if @outPorts.done.isAttached()
          @outPorts.done.send(stream)
          @outPorts.done.disconnect()
          @stream = null
      else
        if @outPorts.content.isAttached()
          @outPorts.content.send(bytes.get_data())
        stream.read_bytes_async(1024, 0, @cancellable, Lang.bind(this, @read_cb))
    catch ex
      @outPorts.content.disconnect() if @outPorts.content.isConnected()
      if @outPorts.done.isAttached()
        @outPorts.done.send(stream)
        @outPorts.done.disconnect()

exports.getComponent = -> new GioStreamReadAll
