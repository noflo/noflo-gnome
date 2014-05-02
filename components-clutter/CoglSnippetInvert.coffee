noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'
{CoglSnippetTemplate} = require '../lib/CoglSnippetTemplate'

class CoglSnippetInvert extends StateComponent
  description: 'GLSL snippet generator for invert a value'
  constructor: ->
    super()
    @inPorts =
      input: new noflo.Port 'object'
    @outPorts =
      snippet: new nolflo.Port 'object'
      uniforms: new noflo.Port 'array'

    @connectParamPort('input', @inPorts.coords)

  process: (state) ->
    return unless @outPorts.snippet.isAttached()

    template = new CoglSnippetTemplate()
    template.outputType = state.input.outputType
    template.code = template.outputType + " @@output@@ = 1 - @@input@@;"
    template.inputs['input'] = state.input

    @outPorts.snippet.send(template)
    @outPorts.snippet.disconnect()

exports.getComponent = -> new CoglSnippetInvert
