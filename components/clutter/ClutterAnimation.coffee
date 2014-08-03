noflo = require 'noflo'

Clutter = imports.gi.Clutter
Lang = imports.lang

class ClutterAnimation extends noflo.Component
  description: 'Animates a ClutterActor'
  icon: 'stop'
  constructor: ->
    @inPorts =
      start: new noflo.Port 'bang'
      pause: new noflo.Port 'bang'
      stop: new noflo.Port 'bang'
      delay: new noflo.Port 'number'
      duration: new noflo.Port 'number'
      easing: new noflo.Port 'string'
      autoreverse: new noflo.Port 'boolean'
      startvalue: new noflo.Port 'number'
      stopvalue: new noflo.Port 'number'
      repeatcount: new noflo.Port 'number'

    @outPorts =
      completed: new noflo.Port 'bang'
      started: new noflo.Port 'bang'
      paused: new noflo.Port 'bang'
      stopped: new noflo.Port 'bang'
      value: new noflo.Port 'number'

    @start = 0
    @stop = 1

    @inPorts.start.on 'data', () =>
      @getTimeline().start()

    @inPorts.pause.on 'data', () =>
      @getTimeline().pause()

    @inPorts.stop.on 'data', () =>
      @getTimeline().stop()

    @inPorts.duration.on 'data', (value) =>
      @getTimeline().duration = value

    @inPorts.delay.on 'data', (value) =>
      @getTimeline().delay = value

    @inPorts.easing.on 'data', (value) =>
      mode = Clutter.AnimationMode[value.toUpperCase()]
      @getTimeline().progress_mode = mode if mode != null && mode != undefined

    @inPorts.autoreverse.on 'data', (value) =>
      @getTimeline().auto_reverse = value

    @inPorts.repeatcount.on 'data', (value) =>
      @getTimeline().repeat_count = value

    @inPorts.startvalue.on 'data', (value) =>
      @start = value

    @inPorts.stopvalue.on 'data', (value) =>
      @stop = value

  getTimeline: () ->
    return @timeline if @timeline
    @timeline = new Clutter.Timeline()
    @startedId = @timeline.connect('started', Lang.bind(this, @started))
    @pausedId = @timeline.connect('paused', Lang.bind(this, @paused))
    @stoppedId = @timeline.connect('stopped', Lang.bind(this, @stopped))
    @completedId = @timeline.connect('completed', Lang.bind(this, @completed))
    @newFrameId = @timeline.connect('new-frame', Lang.bind(this, @progress))
    return @timeline

  progress: (tl, msecs) ->
    return unless @outPorts.value.isAttached()
    value = @start + (@stop - @start) * @timeline.get_progress()
    @outPorts.value.send(value)
    @outPorts.value.disconnect()

  started: () ->
    @setIcon('play')
    return unless @outPorts.started.isAttached()
    @outPorts.started.send(true)
    @outPorts.started.disconnect()

  paused: () ->
    @setIcon('pause')
    return unless @outPorts.paused.isAttached()
    @outPorts.paused.send(true)
    @outPorts.paused.disconnect()

  stopped: () ->
    @setIcon('stop')
    return unless @outPorts.stopped.isAttached()
    @outPorts.stopped.send(true)
    @outPorts.stopped.disconnect()

  completed: () ->
    return unless @outPorts.completed.isAttached()
    @outPorts.completed.send(true)
    @outPorts.completed.disconnect()

  shutdown: () ->
    @timeline.disconnect(@startedId)
    @timeline.disconnect(@pausedId)
    @timeline.disconnect(@stoppedId)
    @timeline.disconnect(@completedId)
    @timeline.disconnect(@newFrameId)
    @timeline.stop()
    delete @startedId
    delete @pausedId
    delete @stoppedId
    delete @completedId
    delete @newFrameId
    delete @timeline

exports.getComponent = -> new ClutterAnimation
