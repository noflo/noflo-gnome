noflo = require 'noflo'

class GetObject extends noflo.Component
  description: 'Get an object from a GtkBuilder object'
  constructor: ->
    @inPorts = new noflo.InPorts
      builder:
        datatype: 'object'
        description: ''
        required: yes
      name:
        datatype: 'string'
        description: ''
        required: yes
    @outPorts = new noflo.OutPorts
      object:
        datatype: 'object'
        description: ''
        required: false
      error:
        datatype: 'object'
        description: ''
        required: false

    @inPorts.builder.on 'data', (@builder) =>
      @getObject()
    @inPorts.name.on 'data', (@name) =>
      @getObject()

  getObject: () ->
    return unless @builder? and @name?
    obj = @builder.get_object(@name)
    if obj?
      @outPorts.object.send obj
      @outPorts.object.disconnect()
    else
      @outPorts.error.send new Error("No object #{@name}")
      @outPorts.error.disconnect()

exports.getComponent = -> new GetObject
