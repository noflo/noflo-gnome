noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

ClutterGst = imports.gi.ClutterGst
Lang = imports.lang

class ClutterGstPlayback extends StateComponent
  description: 'extracts video frame from a stream'
  constructor: ->
    super()
    @inPorts =
      start: new noflo.Port 'bang'
      pause: new noflo.Port 'bang'
      stop: new noflo.Port 'bang'
      filename: new noflo.Port 'string'
      progress: new noflo.Port 'number'
      volume: new noflo.Port 'number'
    @outPorts =
      started: new noflo.Port 'bang'
      paused: new noflo.Port 'bang'
      stopped: new noflo.Port 'bang'
      frame: new noflo.Port 'object'
      progress: new noflo.Port 'number'

    @connectParamPort('start', @inPorts.start)
    @connectParamPort('filename', @inPorts.filename)

    @inPorts.stop.on 'data', (data) =>
      @stop() if @data

    @inPorts.volume.on 'data', (value) =>
      return unless @player
      @player.audio_volume = value

    @inPorts.progress.on 'data', (value) =>
      return unless @player
      @player.progress = value

  process: (state) ->
    @stop()
    if state.start
      player = new ClutterGst.Playback()
      player.set_filename(state.filename)
      @start(player)

  start: (player) ->
    @player = player
    @player.set_playing(true)
    @newFrameId = @player.connect('new-frame', Lang.bind(this, @newFrame))
    @progressId = @player.connect('notify::progress', Lang.bind(this, @progress))
    if @outPorts.started.isAttached()
      @outPorts.started.send(true)
      @outPorts.started.disconnect()

  pause: () ->
    @player.set_playing(false)

  stop: () ->
    return unless @player
    if @newFrameId
      @outPorts.frame.disconnect() if @outPorts.frame.isConnected()
      @player.disconnect(@newFrameId)
      delete @newFrameId
    if @progressId
      @outPorts.progress.disconnect() if @outPorts.progress.isConnected()
      @player.disconnect(@progressId)
      delete @progressId
    @player.set_playing(false)
    if @outPorts.stopped.isAttached()
      @outPorts.stopped.send(true)
      @outPorts.stopped.disconnect()
    delete @player

  newFrame: (player, frame) ->
    @outPorts.frame.send(frame) if @outPorts.frame.isAttached()

  progress: (player, spec) ->
    @outPorts.progress.send(player.progress) if @outPorts.progress.isAttached()

  shutdown: () ->
    @stop()

exports.getComponent = -> new ClutterGstPlayback
