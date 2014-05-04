noflo = require 'noflo'
Lang = imports.lang

class ListenProperty extends noflo.Component
  description: 'Listen to a signal on a given object'
  icon: 'bolt'
  constructor: ->
    @inPorts = new noflo.InPorts
      object:
        datatype: 'object'
        description: 'Object instance to listen at'
        required: yes
      property:
        datatype: 'string'
        description: 'Property change to listen to'
        required: yes
    @outPorts = new noflo.OutPorts
      object:
        datatype: 'object'
        description: 'Object been listen to'
        required: no
      value:
        datatype: 'all'
        description: 'Property value'
        required: no

    @inPorts.object.on 'data', (@object) =>
      @updateListener()
    @inPorts.property.on 'data', (@property) =>
      @updateListener()

  updateListener: () ->
    return unless @object? and @property?
    @disconnectListener()
    @listener = @object.connect "notify::#{@property}", Lang.bind @, () =>
      @outPorts.object.send @object
      @outPorts.object.disconnect()
      @outPorts.value.send @object[@property]
      @outPorts.value.disconnect()

  disconnectListener: () ->
    if @listener
      @object.disconnect @listener
      delete @listener

  shutdown: () ->
    @disconnectListener()

exports.getComponent = -> new ListenProperty
