noflo = require 'noflo'

Clutter = imports.gi.Clutter

class ClutterClick extends noflo.Component
  description: 'Detects click events from a stream of ClutterEvent'
  constructor: ->
    @inPorts =
      event: new noflo.Port 'object'
      reset: new noflo.Port 'bang'
    @outPorts =
      event: new noflo.Port 'object'
      consumed: new noflo.Port 'object'
      click: new noflo.Port 'bang'

    @pressed = false
    @isTouch = false

    @inPorts.event.on 'data', (event) =>
      switch event.type()
        when Clutter.EventType.BUTTON_PRESS
          @press = true
          @isTouch = false
        when Clutter.EventType.TOUCH_BEGIN
          @press = true
          @isTouch = true
        when Clutter.EventType.TOUCH_CANCEL
          @reset() if @isTouch
        when Clutter.EventType.BUTTON_RELEASE
          if @press && !@isTouch && @outPorts.click.isAttached()
            @press = false
            @outPorts.click.send(true)
            @outPorts.click.disconnect()
        when Clutter.EventType.TOUCH_END
          @consumed(event)
          if @press && @isTouch && @outPorts.click.isAttached()
            @press = false
            @outPorts.click.send(true)
            @outPorts.click.disconnect()
        else
          @unconsumed(event)

    @inPorts.reset.on 'data', (data) =>
      @reset()

  consumed: (event) ->
    return unless @outPorts.consumed.isAttached()
    @outPorts.consumed.send(event)
    @outPorts.consumed.disconnect()

  unconsumed: (event) ->
    return unless @outPorts.event.isAttached()
    @outPorts.event.send(event)
    @outPorts.event.disconnect()

  reset: () ->
    @pressed = false

  shutdown: () ->
    @reset()

exports.getComponent = -> new ClutterClick
