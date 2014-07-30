noflo = require 'noflo'

class ListenSignal extends noflo.Component
  description: 'Listen to a signal on a given object'
  icon: 'bolt'
  constructor: ->
    @inPorts = new noflo.InPorts
      object:
        datatype: 'object'
        description: 'Object instance to listen at'
        required: yes
      signal:
        datatype: 'string'
        description: 'Signal to listen to'
        required: yes
    @outPorts = new noflo.OutPorts
      object:
        datatype: 'object'
        description: 'Object instance to listen at'
        required: no

    @inPorts.object.on 'data', (object) =>
      @object = object
      @updateListener()
    @inPorts.signal.on 'data', (signal) =>
      @signal = signal
      @updateListener()

  updateListener: () ->
    return unless @object? and @signal?
    @disconnectListener()
    @listener = @object.connect @signal, () =>
      @outPorts.object.send true
      @outPorts.object.disconnect()

  disconnectListener: () ->
    if @listener
      @object.disconnect @listener
      delete @listener

  shutdown: () ->
    @disconnectListener()

exports.getComponent = -> new ListenSignal
