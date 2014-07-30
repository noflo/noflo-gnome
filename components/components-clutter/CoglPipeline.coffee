noflo = require 'noflo'
InBoundPorts = require '../lib/InBoundPorts'
OutBoundPorts = require '../lib/OutBoundPorts'

Cogl = imports.gi.Cogl

class CoglPipeline extends noflo.Component
  description: 'emits one CoglPipeline'
  constructor: ->
    @inPorts = new InBoundPorts
    @inPorts.add 'context',
      datatype: 'object'
      description: 'a CoglContext'
      required: true
    @outPorts = new OutBoundPorts
    @outPorts.add 'pipeline',
      datatype: 'object'
      description: 'a CoglPipeline'
      required: false
      getValue: () => @getPipeline()

    @inPorts.on 'context', 'data', (context) =>
      @context = context

  getPipeline: () ->
    return @pipeline if @pipeline
    @pipeline = new Cogl.Pipeline(@context)

exports.getComponent = -> new CoglPipeline
