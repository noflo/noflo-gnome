noflo = require 'noflo'
InBoundPorts = require '../lib/InBoundPorts'
OutBoundPorts = require '../lib/OutBoundPorts'

class CoglPipelineCopy extends noflo.Component
  description: 'Copy a CoglPipeline'
  constructor: ->
    @inPorts = new InBoundPorts
    @inPorts.add 'pipeline',
      datatype: 'object'
      description: 'a CoglPipeline'
      required: true
    @outPorts = new OutBoundPorts
    @outPorts.add 'pipeline',
      datatype: 'object'
      description: 'a copy of a CoglPipeline'
      getValue: () => @getPipelineCopy()

  getPipelineCopy: () ->
    return @pipeline.copy()

exports.getComponent = -> new CoglPipelineCopy
