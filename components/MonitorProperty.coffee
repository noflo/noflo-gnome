noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

Lang = imports.lang

class MonitoryProperty extends StateComponent
  description: 'Expose the value of a property of an object'
  constructor: ->
    super()
    @inPorts =
      object: new noflo.Port 'object'
      property: new noflo.Port 'string'

    @outPorts =
      value: new noflo.ArrayPort

    @connectParamPort('object', @inPorts.object)
    @connectParamPort('property', @inPorts.property)

  process: (state) ->
    @unlistenObject()
    @listenObject(state.object, state.property)

  listenObject: (object, property) ->
    @object = object
    @property = property
    @object.connect('notify::' + property, Lang.bind(this, @notifyProperty))

  unlistenObject: () ->
    return unless @notifyId
    @object.disconnect(@notifyId)
    delete @notifyId

  notifyProperty: ->
    return unless @outPorts.value.isAttached()
    @outPorts.value.send(@object[@property])
    @outPorts.value.disconnect()

  shutdown: ->
    @unlistenObject()

exports.getComponent = -> new MonitoryProperty
