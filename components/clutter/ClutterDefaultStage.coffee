noflo = require 'noflo'

Clutter = imports.gi.Clutter
Lang = imports.lang

class ClutterDefaultStage extends noflo.Component
  description: 'The default ClutterStage'
  constructor: ->
    @inPorts =
      active: new noflo.Port 'boolean'

    @outPorts =
      object: new noflo.Port 'object'
      capturedevent: new noflo.Port 'object'
      event: new noflo.Port 'object'

    @portToObject = {}
    @objectToPort = {}
    @cache = {}
    @mapInOutPort('width', 'width', 'number')
    @mapInOutPort('height', 'height', 'number')
    @mapInOutPort('content', 'content', 'object')
    @mapInOutPort('reactive', 'reactive', 'boolean')

    @inPorts.active.on 'data', (active) =>
      if active
        @activateActor()
      else
        @deactivateActor()
    @outPorts.object.on 'attach', (socket) =>
      socket.send(@getActor())
      socket.disconnect()

    @eventRefCount = 0
    @outPorts.event.on 'attach', () =>
      @eventRef()
    @outPorts.event.on 'detach', () =>
      @eventUnref()
    @capturedEventRefCount = 0
    @outPorts.capturedevent.on 'attach', () =>
      @capturedEventRef()
    @outPorts.capturedevent.on 'detach', () =>
      @capturedEventUnref()

  # Actor creation/management

  getActor: () ->
    return @actor if @actor?
    stageManager = Clutter.StageManager.get_default()
    @actor = stageManager.get_default_stage()
    @actor = new Clutter.Stage() unless @actor?
    if @outPorts.object.isAttached()
      @outPorts.object.send(@actor)
      @outPorts.object.disconnect()
    @notifyId = @actor.connect('notify', Lang.bind(this, @onPropertyNotify))
    return @actor

  activateActor: () ->
    @getActor().show()

  deactivateActor: () ->
    @getActor().hide()

  mapInOutPort: (portName, property, type) ->
    inPort = @inPorts[portName] = new noflo.Port type
    outPort = @outPorts[portName] = new noflo.Port type
    inPort.on 'data', (data) =>
      @getActor()[property] = data
    outPort.on 'attach', (socket) =>
      socket.send(@getActor()[property])
      socket.disconnect()
    @objectToPort[property] = portName
    @portToObject[portName] = property

  onPropertyNotify: (actor, spec) ->
    portName = @objectToPort[spec.name]
    return unless portName
    port = @outPorts[portName]
    return unless port.isAttached()
    port.send(@getActor()[spec.name])
    port.disconnect()

  # Event listening

  eventRef: () ->
    needConnect = if @eventRefCount < 1 then true else false
    @eventRefCount += 1
    @eventId = @getActor().connect('event', Lang.bind(this, @eventReceived))

  eventUnref: () ->
    @eventRefCount -= 1
    if @eventRefCount == 0 && @eventId
      @getActor().disconnect(@eventId)
      delete @eventId

  capturedEventRef: () ->
    needConnect = if @capturedEventRefCount < 1 then true else false
    @capturedEventRefCount += 1
    @capturedEventId = @getActor().connect('captured-event', Lang.bind(this, @capturedEventReceived))

  capturedEventUnref: () ->
    @capturedEventRefCount -= 1
    if @capturedEventRefCount == 0 && @capturedEventId
      @getActor().disconnect(@capturedEventId)
      delete @capturedEventId

  stopEventListening: () ->
    if @eventId
      @getActor().disconnect(@eventId)
      delete @eventId
    if @capturedEventId
      @getActor().disconnect(@capturedEventId)
      delete @capturedEventId

  capturedEventReceived: (actor, event) ->
    event.consumed = false
    @outPorts.capturedevent.send(event)
    @outPorts.capturedevent.disconnect()
    return event.consumed

  eventReceived: (actor, event) ->
    event.consumed = false
    @outPorts.event.send(event)
    @outPorts.event.disconnect()
    return event.consumed

  # Shutdown

  shutdown: () ->
    @deactivateActor()

exports.getComponent = -> new ClutterDefaultStage
