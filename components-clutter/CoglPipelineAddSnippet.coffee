noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

Cogl = imports.gi.Cogl

class CoglPipelineAddSnippet extends StateComponent
  description: 'Adds a CoglSnippet to a CoglPipeline'
  constructor: ->
    super()
    @inPorts =
      pipeline: new noflo.Port 'object'
      snippet: new noflo.Port 'object'
    @outPorts =
      pipeline: new noflo.ArrayPort 'object'

    @connectParamPort('pipeline', @inPorts.pipeline)
    @connectParamPort('snippet', @inPorts.snippet)

  process: (state) ->
    if @outPorts.pipeline.isAttached()
      state.pipeline.add_snippet(state.snippet)
      @outPorts.pipeline.send(state.pipeline)
      @outPorts.pipeline.disconnect()

exports.getComponent = -> new CoglPipelineAddSnippet
