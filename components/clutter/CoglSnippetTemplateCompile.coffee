noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'
{CoglSnippetCompiler} = require '../lib/CoglSnippetCompiler'

class CoglSnippetInvert extends StateComponent
  description: 'GLSL snippet generator for invert a value'
  constructor: ->
    @inPorts =
      input: new noflo.Port 'object'
    @outPorts =
      code: new nolflo.Port 'object'

  process: (state) ->
    return unless @outPorts.code.isAttached()

    template = new CoglSnippetTemplate()
    template.outputType = state.input.outputType
    template.code = template.outputType + " @@output@@ = 1 - @@input@@;"
    template.inputs['input'] = state.input

    @outPorts.code.send(template)
    @outPorts.code.disconnect()

exports.getComponent = -> new CoglSnippetInvert
