noflo = require 'noflo'

class Pack extends noflo.Component
  description: 'Pack a GtkWidget into a GtkBox'
  icon: 'sign-in'
  constructor: ->
    @inPorts = new noflo.InPorts
      parent:
        datatype: 'object'
        description: 'Parent instance'
        required: yes
      child:
        datatype: 'object'
        description: 'Child instance'
        required: yes
      expand:
        datatype: 'boolean'
        description: ''
        required: no
      fill:
        datatype: 'boolean'
        description: ''
        required: no
      padding:
        datatype: 'number'
        description: ''
        required: no
      end:
        datatype: 'boolean'
        description: ''
        required: no
    @outPorts = new noflo.OutPorts
      child:
        datatype: 'object'
        description: ''
        required: false

    @expand = false
    @fill = false
    @padding = 0
    @end = false

    @inPorts.expand.on 'data', (value) =>
      @expand = value
    @inPorts.fill.on 'data', (value) =>
      @fill = value
    @inPorts.padding.on 'data', (padding) =>
      @padding = padding

    @inPorts.parent.on 'data', (parent) =>
      @parent = parent
      @packWidget()
    @inPorts.child.on 'data', (child) =>
      @child = child
      @packWidget()

  packWidget: () ->
    return unless @parent? and @child?
    if @end
      @parent.pack_end(@child, @expand, @fill, @padding)
    else
      @parent.pack_start(@child, @expand, @fill, @padding)
    @outPorts.child.send @child
    @outPorts.child.disconnect()

exports.getComponent = -> new Pack
