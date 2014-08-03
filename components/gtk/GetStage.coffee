noflo = require 'noflo'

class GetStage extends noflo.Component
  description: 'Gets the ClutterStage associated to a GtkClutterEmbedded'
  constructor: ->
    @inPorts = new noflo.InPorts
      embedded:
        datatype: 'object'
        description: ''
        required: true
    @outPorts = new noflo.OutPorts
      stage:
        datatype: 'object'
        description: ''
        required: false

    @inPorts.embedded.on 'data', (embedded) =>
      @outPorts.stage.send embedded.get_stage()
      @outPorts.stage.disconnect()

exports.getComponent = -> new GetStage
