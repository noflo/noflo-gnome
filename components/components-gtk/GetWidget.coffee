noflo = require 'noflo'

class GetWidget extends noflo.Component
  description: 'Gets the GtkWidget associated to a GtkClutterActor'
  constructor: ->
    @inPorts = new noflo.InPorts
      actor:
        datatype: 'object'
        description: ''
        required: true
    @outPorts = new noflo.OutPorts
      widget:
        datatype: 'object'
        description: ''
        required: false

    @inPorts.actor.on 'data', (actor) =>
      @outPorts.widget.send actor.get_widget()
      @outPorts.widget.disconnect()

exports.getComponent = -> new GetWidget
