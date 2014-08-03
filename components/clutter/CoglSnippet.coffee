noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'
Cogl = imports.gi.Cogl

class CoglSnippet extends StateComponent
  description: 'CoglSnippet'
  constructor: ->
    super()
    @inPorts =
      code: new noflo.Port 'string'
      hook: new noflo.Port 'string'
    @outPorts =
      snippet: new noflo.ArrayPort 'object'

    @connectParamPort('hook', @inPorts.hook)
    @connectParamPort('code', @inPorts.code)

  process: (state) ->
    return unless @outPorts.snippet.isAttached()
    snippet = new Cogl.Snippet(Cogl.SnippetHook[state.hook.toUpperCase()], '', state.code)
    @outPorts.snippet.send(snippet)
    @outPorts.snippet.disconnect()

exports.getComponent = -> new CoglSnippet
