noflo = require 'noflo'

class AddChild extends noflo.Component
  description: 'Add an actor as a child of a parent'
  constructor: ->
    @inPorts = new noflo.InPorts
      parent:
        datatype: 'object'
        description: ''
        required: true
      child:
        datatype: 'object'
        description: ''
        required: true
    @outPorts = new noflo.OutPorts
      child:
        datatype: 'object'
        description: ''
        required: false

    @inPorts.parent.on 'data', (parent) =>
      @parent = parent
      @addChild()
    @inPorts.child.on 'data', (child) =>
      @child = child
      @addChild()

  addChild: () ->
    return unless @parent? and @child?
    @parent.add_child(@child)
    @outPorts.child.send @child
    @outPorts.child.disconnect()

exports.getComponent = -> new AddChild
