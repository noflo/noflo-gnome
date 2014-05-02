noflo = require 'noflo'

Lang = imports.lang
GObject = imports.gi.GObject
Clutter = imports.gi.Clutter
ClutterUtils = imports.clutterUtils


class ClutterPipelineContent extends noflo.Component
  description: 'Create a ClutterContent object for a CoglPipeline'
  constructor: ->
    @inPorts =
      pipeline: new noflo.Port 'object'
    @outPorts =
      content: new noflo.Port 'object'

    @inPorts.pipeline.on 'data', (pipeline) =>
      if @outPorts.content.isAttached()
        content = new ClutterUtils.PipelineContent()
        content.pipeline = pipeline
        @outPorts.content.send(content)
        @outPorts.content.disconnect()

exports.getComponent = -> new ClutterPipelineContent
