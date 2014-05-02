noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

GLib = imports.gi.GLib

class GLibSpawn extends StateComponent
  description: 'Spawns a new process'
  constructor: ->
    super()
    @inPorts =
      cwd: new noflo.Port 'string'
      command: new noflo.Port 'string'
      args: new noflo.Port 'string'
      env: new noflo.Port 'object'
    @outPorts =
      inputfd: new noflo.ArrayPort 'number'
      outputfd: new noflo.ArrayPort 'number'
      errorfd: new noflo.ArrayPort 'number'
      pid: new noflo.ArrayPort 'number'

    @connectParamPort('cwd', @inPorts.cwd)
    @connectParamPort('command', @inPorts.command)
    @connectParamPort('args', @inPorts.args)
    @connectParamPort('env', @inPorts.env)

  process: (state) ->
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
