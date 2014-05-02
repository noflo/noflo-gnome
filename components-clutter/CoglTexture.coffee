noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

Cogl = imports.gi.Cogl

class CoglTexture extends StateComponent
  description: 'creates a new CoglTexture from a file'
  constructor: ->
    super()
    @inPorts =
      filename: new noflo.Port 'string'
      context: new noflo.Port 'object'
    @outPorts =
      texture: new noflo.ArrayPort 'object'

    @connectParamPort('context', @inPorts.context)
    @connectParamPort('filename', @inPorts.filename)

  process: (state) ->
    if @outPorts.texture.isAttached()
      texture = Cogl.Texture2D.new_from_file(state.context, state.filename, Cogl.TextureFlags.NO_ATLAS, Cogl.PixelFormat.ANY)
      @outPorts.texture.send(texture)
      @outPorts.texture.disconnect()

exports.getComponent = -> new CoglTexture
