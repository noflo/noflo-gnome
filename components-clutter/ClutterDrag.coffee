noflo = require 'noflo'

Clutter = imports.gi.Clutter

class ClutterDrag extends noflo.Component
  description: 'Detects a drag motion events from a stream of ClutterEvent'
  constructor: ->
    @inPorts =
      actorevent: new noflo.Port 'object'
      stageevent: new noflo.Port 'object'
      reset: new noflo.Port 'bang'
    @outPorts =
      event: new noflo.Port 'object'
      consumed: new noflo.Port 'object'
      dragbegin: new noflo.Port 'bang'
      dragprogress: new noflo.Port 'object'
      dragend: new noflo.Port 'bang'

    @start = null

    @inPorts.actorevent.on 'data', (event) =>
      switch event.type()
        when Clutter.EventType.BUTTON_PRESS, Clutter.EventType.TOUCH_BEGIN
          @unconsumed(event) unless @startDragging(event)
        else
          @unconsumed(event)
    @inPorts.stageevent.on 'data', (event) =>
      return unless @start
      switch event.type()
        when Clutter.EventType.TOUCH_CANCEL
          @consumed(event)
          @reset()
        when Clutter.EventType.BUTTON_RELEASE, Clutter.EventType.TOUCH_END
          @unconsumed(event) unless @stopDragging(event)
        when Clutter.EventType.MOTION, Clutter.EventType.TOUCH_UPDATE
          @unconsumed(event) unless @updateDragging(event)
        else
          @unconsumed(event)
    @inPorts.reset.on 'data', (data) =>
      @reset()

  startDragging: (event) ->
    return false if @start
    @consumed(event)
    xy = event.get_coords()
    @start =
      x: xy[0]
      y: xy[1]
    if @outPorts.dragbegin.isAttached()
      @outPorts.dragbegin.send(true)
      @outPorts.dragbegin.disconnect()
    if @outPorts.dragprogress.isAttached()
      @outPorts.dragprogress.send({ x: 0, y: 0 })
    return true

  stopDragging: (event) ->
    return false unless @start
    @consumed(event)
    xy = event.get_coords()
    if @outPorts.dragprogress.isAttached()
      @outPorts.dragprogress.send({ x: xy[0] - @start.x, y: xy[1] - @start.y })
    @start = null
    if @outPorts.dragend.isAttached()
      @outPorts.dragend.send(true)
      @outPorts.dragend.disconnect()
    return true

  updateDragging: (event) ->
    return false unless @start
    return true unless @outPorts.dragprogress.isAttached()
    @consumed(event)
    xy = event.get_coords()
    @outPorts.dragprogress.send({ x: xy[0] - @start.x, y: xy[1] - @start.y })
    return true

  consumed: (event) ->
    return unless @outPorts.consumed.isAttached()
    @outPorts.consumed.send(event)
    @outPorts.consumed.disconnect()

  unconsumed: (event) ->
    return unless @outPorts.event.isAttached()
    @outPorts.event.send(event)
    @outPorts.event.disconnect()

  reset: () ->
    delete @start

  shutdown: () ->
    @reset()

exports.getComponent = -> new ClutterDrag
