noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

class CoglPipelineSetTexture extends StateComponent
  description: 'Set a texture on a CoglPipeline'
  constructor: ->
    super()
    @inPorts =
      pipeline: new noflo.Port 'object'
      texture: new noflo.Port 'object'
      layer: new noflo.Port 'number'
    @outPorts =
      pipeline: new noflo.ArrayPort 'object'

    @connectParamPort('pipeline', @inPorts.pipeline)
    @connectParamPort('texture', @inPorts.texture)
    @connectParamPort('layer', @inPorts.layer)

  process: (state) ->
    if @outPorts.pipeline.isAttached()
      state.pipeline.set_layer_texture(state.layer, state.texture)
      @outPorts.pipeline.send(state.pipeline)
      @outPorts.pipeline.disconnect()

exports.getComponent = -> new CoglPipelineSetTexture
