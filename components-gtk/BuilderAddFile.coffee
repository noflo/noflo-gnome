noflo = require 'noflo'

class BuilderAddFile extends noflo.Component
  description: 'Add file to GtkBuilder object'
  icon: 'plus'
  constructor: ->
    @inPorts = new noflo.InPorts
      builder:
        datatype: 'object'
        description: ''
        required: yes
      filename:
        datatype: 'all'
        description: ''
        required: yes
    @outPorts = new noflo.OutPorts
      builder:
        datatype: 'object'
        description: ''
        required: no
      error:
        datatype: 'object'
        description: ''
        required: no

    @inPorts.builder.on 'data', (@builder) =>
      @loadFile()
    @inPorts.filename.on 'data', (@f) =>
      @loadFile()

  loadFile: () ->
    return unless @builder? and @f?
    try
      log typeof(@f)
      log @builder
      log @f
      @builder.add_from_file @f
    catch e
      @outPorts.error.send e
      @outPorts.error.disconnect()
      return
    @outPorts.builder.send @builder
    @outPorts.builder.disconnect()

exports.getComponent = -> new BuilderAddFile
