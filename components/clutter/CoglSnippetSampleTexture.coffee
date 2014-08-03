noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'
{CoglSnippetTemplate} = require '../lib/CoglSnippetTemplate'

class CoglSnippetSampleTexture extends StateComponent
  description: 'GLSL snippet generator for sampling a texture'
  constructor: ->
    super()
    @inPorts =
      layer: new noflo.Port 'number'
      coords: new noflo.Port 'object'
    @outPorts =
      snippet: new nolflo.Port 'object'
      uniforms: new noflo.Port 'array'

    @connectParamPort('layer', @inPorts.layer)
    @connectParamPort('coords', @inPorts.coords)

  process: (state) ->
    return unless @outPorts.snippet.isAttached()

    template = new CoglSnippetTemplate()
    template.outputType = 'vec4'
    template.code = "vec4 @@output@@ = texture2D(@@layer@@, @@coords@@);"
    template.inputs['layer'] = state.layer
    template.inputs['coords'] = state.coords

    @outPorts.snippet.send(template)
    @outPorts.snippet.disconnect()

exports.getComponent = -> new CoglSnippetSampleTexture
