noflo = require 'noflo'
Lang = imports.lang

class ListenSignal extends noflo.Component
  description: 'Listen to a signal on a given object'
  icon: 'bolt'
  constructor: ->
    @inPorts = new noflo.InPorts
      in:
        datatype: 'object'
        description: 'Object instance to listen at'
        required: true
      signal:
        datatype: 'object'
        description: 'Signal to listen to'
        required: true
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'bang'
        description: 'Signal output'
        required: false

    @inPorts.in.on 'data', (object) =>
      @object = object
    @inPorts.signal.on 'data', (signal) =>
      @signal = signal

  updateListener: () ->
    return unless @object? and @signal?
    @disconnectListener()
    @listener = @object.connect @signal, Lang.bind @, () =>
      @outPorts.out.send true
      @outPorts.out.disconnect()

  disconnectListener: () ->
    if @listener
      @object.disconnect @listener
      delete @listener

  shutdown: () ->
    @disconnectListener()

exports.getComponent = -> new ListenSignal
