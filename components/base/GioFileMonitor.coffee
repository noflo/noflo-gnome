noflo = require 'noflo'

Gio = imports.gi.Gio
Lang = imports.lang

class GioFileMonitor extends noflo.Component
  description: 'Monitors a file for changes'
  constructor: ->
    @inPorts =
      filename: new noflo.Port 'string'
      start: new noflo.Port 'bang'
      stop: new noflo.Port 'bang'
    @outPorts =
      changed: new noflo.ArrayPort 'boolean'

    @inPorts.start.on 'data', (data) =>
      @shouldStart = true
      @start(@filename) if @filename

    @inPorts.stop.on 'data', (data) =>
      @stop()

    @inPorts.filename.on 'data', (filename) =>
      @filename = filename
      if @started
        @stop()
        @start(@filename)
      else if @shouldStart
        @start(@filename)

  changed: (monitor, file, other_file, event_type) ->
    return if event_type != Gio.FileMonitorEvent.CHANGES_DONE_HINT
    if @outPorts.changed.isAttached()
      @outPorts.changed.send(true)
      @outPorts.changed.disconnect()

  start: (filename) ->
    file = Gio.File.new_for_path(filename)
    @monitor = file.monitor(Gio.FileMonitorFlags.NONE, null)
    @monitorId = @monitor.connect('changed', Lang.bind(this, @changed))
    @started = true

  stop: ->
    @shouldStart = false
    return unless @started
    @monitor.disconnect(@monitorId)
    @started = false

  shutdown: ->
    @stop()

exports.getComponent = -> new GioFileMonitor
