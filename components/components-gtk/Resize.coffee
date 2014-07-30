noflo = require 'noflo'

class Resize extends noflo.Component
  description: 'Resize a GtkWindow'
  constructor: ->
    @inPorts = new noflo.InPorts
      window:
        datatype: 'object'
        description: ''
        required: yes
      width:
        datatype: 'number'
        description: ''
        required: no
      height:
        datatype: 'number'
        description: ''
        required: no
    @outPorts = new noflo.OutPorts
      window:
        datatype: 'object'
        description: ''
        required: no

    @width = @height = -1

    @inPorts.width.on 'data', (@width) =>
    @inPorts.height.on 'data', (@height) =>
    @inPorts.window.on 'data', (win) =>
      win.resize(@width, @height)
      @outPorts.window.send win
      @outPorts.window.disconnect()

exports.getComponent = -> new Resize
