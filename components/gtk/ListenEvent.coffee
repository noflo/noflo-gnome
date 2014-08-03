noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Listen events on a GtkWidget'

  c.inPorts.add 'widget',
    datatype: 'object'
    description: 'Widget to listen events from'
    process: (event, payload) ->
      return unless event is 'data'
      c.updateWidget payload
      return
  c.inPorts.add 'reset',
    datatype: 'bang'
    description: 'Reset processing'
    process: (event, payload) ->
      return unless event is 'disconnect'
      c.updateWidget null
      return

  c.outPorts.add 'event',
    datatype: 'object'
    description: 'GdkEvent from the widget'

  c.updateWidget = (widget) ->
    if @widget
      @widget.disconnect @listener
      delete @listener
    @widget = widget
    if @widget
      @listener = @widget.connect 'event', (widget, event) =>
        event.consumed = false
        @outPorts.event.send event
        @outPorts.event.disconnect()
        return event.consumed

  c.shutdown = () ->
    @updateWidget null
  c
