noflo = require 'noflo'

System = imports.system

class SystemRunGC extends noflo.Component
  description: 'Runs the garbage collector'
  constructor: ->
    super()
    @inPorts =
      kick: new noflo.Port 'bang'

    @inPorts.kick.on 'data', () =>
      System.gc()

exports.getComponent = -> new SystemRunGC
