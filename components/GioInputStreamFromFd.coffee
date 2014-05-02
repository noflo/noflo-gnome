noflo = require 'noflo'

Gio = imports.gi.Gio

class GioInputStreamFromFd extends noflo.Component
  description: 'creates a GInputStream from a file descriptors'
  constructor: ->
    super()
    @inPorts =
      fd: new noflo.Port 'number'
    @outPorts =
      stream: new noflo.ArrayPort 'object'

    @inPorts.fd.on 'data', (fd) =>
      return unless @outPorts.stream.isAttached()
      stream = Gio.UnixInputStream.new(fd, true)
      @outPorts.stream.send(stream)
      @outPorts.stream.disconnect()

exports.getComponent = -> new GioInputStreamFromFd
