noflo = require 'noflo'
GLib = imports.gi.GLib

class GLibSpawn extends noflo.Component
  description: 'Spawns a new process'
  constructor: ->
    super()
    @inPorts.add 'cwd',
      datatype: 'string'
    @inPorts.add 'command',
      datatype: 'string'
    @inPorts.add 'args',
      datatype: 'string'
    @inPorts.add 'env',
      datatype: 'object'

    @outPorts.add 'inputfd',
      datatype: 'number'
    @outPorts.add 'outputfd',
      datatype: 'number'
    @outPorts.add 'errorfd',
      datatype: 'number'
    @outPorts.add 'pid',
      datatype: 'number'

    noflo.helpers.WirePattern @,
      in: ['command', 'args']
      params: ['cwd', 'command', 'args', 'env']
      out: ['inputfd', 'outputfd', 'errorfd', 'pid']
      forwardGroups: true
      async: false,
      (data, groups, out, callback) =>
        args = [state.command].concat(state.args.split(" "))

        [success, pid, inputfd, outputfd, errorfd] = GLib.spawn_async_with_pipes(state.cwd, args, null, GLib.SpawnFlags.DEFAULT, null)
        return unless success

        if @outPorts.inputfd.isAttached()
          @outPorts.inputfd.send(inputfd)
          @outPorts.inputfd.disconnect()
        if @outPorts.outputfd.isAttached()
          @outPorts.outputfd.send(outputfd)
          @outPorts.errorfd.disconnect()
        if @outPorts.errorfd.isAttached()
          @outPorts.errorfd.send(errorfd)
          @outPorts.errorfd.disconnect()
        if @outPorts.pid.isAttached()
          @outPorts.pid.send(pid)
          @outPorts.pid.disconnect()

exports.getComponent = -> new GLibSpawn
