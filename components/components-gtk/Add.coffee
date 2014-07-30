noflo = require 'noflo'

class Add extends noflo.Component
  description: 'Add a GtkWidget into another one'
  icon: 'sign-in'
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
      parent:
        datatype: 'object'
        description: ''
        required: false
      child:
        datatype: 'object'
        description: ''
        required: false

    @inPorts.parent.on 'data', (parent) =>
      @parent = parent
      @addWidget()

    @inPorts.child.on 'data', (child) =>
      @child = child
      @addWidget()

  addWidget: () ->
    return unless @parent? and @child?
    @parent.add(@child)
    @outPorts.parent.send @parent
    @outPorts.parent.disconnect()
    @outPorts.child.send @child
    @outPorts.child.disconnect()

exports.getComponent = -> new Add
