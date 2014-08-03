noflo = require 'noflo'

Clutter = imports.gi.Clutter
Lang = imports.lang

class ClutterActor extends noflo.Component
  description: 'A ClutterActor on the Stage'
  constructor: ->
    @inPorts =
      active: new noflo.Port 'boolean'

    @outPorts =
      object: new noflo.Port 'object'
      capturedevent: new noflo.Port 'object'
      event: new noflo.Port 'object'

    @portToObject = {}
    @objectToPort = {}
    @actor = null

    @mapInOutPort('x', 'x', 'number')
    @mapInOutPort('y', 'y', 'number')
    @mapInOutPort('z', 'z-position', 'number')
    @mapInOutPort('scalex', 'scale-x', 'number')
    @mapInOutPort('scaley', 'scale-y', 'number')
    @mapInOutPort('pivot-x', 'pivot-point', 'number', 'pointXToPoint', 'pointToPointX')
    @mapInOutPort('pivot-y', 'pivot-point', 'number', 'pointYToPoint', 'pointToPointY')
    @mapInOutPort('pivot-z', 'pivot-point-z', 'number')
    @mapInOutPort('rot-x', 'rotation-angle-x', 'number')
    @mapInOutPort('rot-y', 'rotation-angle-y', 'number')
    @mapInOutPort('rot-z', 'rotation-angle-z', 'number')
    @mapInOutPort('width', 'width', 'number')
    @mapInOutPort('height', 'height', 'number')
    @mapInOutPort('opacity', 'opacity', 'number')
    @mapInOutPort('content', 'content', 'object')
    @mapInOutPort('bgcolor', 'background-color', 'object', 'objectToColor')
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
    return @actor if @actor
    @actor = new Clutter.Actor()
    @notifyId = @actor.connect('notify', Lang.bind(this, @onPropertyNotify))
    if @outPorts.object.isAttached()
      @outPorts.object.send(@actor)
      @outPorts.object.disconnect()
    return @actor

  activateActor: () ->
    return if @getActor().get_parent() != null
    stageManager = Clutter.StageManager.get_default()
    stage = stageManager.list_stages()[0]

    actor = @getActor()
    stage.add_child(actor)
    if @outPorts.object.isAttached()
      @outPorts.object.send(actor)
      @outPorts.object.disconnect()

  deactivateActor: () ->
    actor = @getActor()
    parent = actor.get_parent()
    return unless parent != null
    parent.remove_child(actor)

  destroyActor: () ->
    return unless @actor
    @deactivateActor()
    @stopEventListening()
    @actor.destroy()
    delete @actor

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

  # Automatic property wiring

  convertPortIfNeeded: (portName, value) ->
    return value unless @portToObject[portName].convert
    return this[@portToObject[portName].convert](value)

  convertPropertyIfNeeded: (property, value) ->
    return value unless @objectToPort[property].convert
    return this[@objectToPort[property].convert](value)

  mapInOutPort: (portName, property, type, convertIn, convertOut) ->
    inPort = @inPorts[portName] = new noflo.Port type
    outPort = @outPorts[portName] = new noflo.Port type

    @objectToPort[property] =
      portName: portName
      convert: convertOut
    @portToObject[portName] =
      property: property
      convert: convertIn

    inPort.on 'data', (data) =>
      @getActor()[property] = @convertPortIfNeeded(portName, data)
    outPort.on 'attach', (socket) =>
      socket.send(@convertPropertyIfNeeded(property, @getActor()[property]))
      socket.disconnect()

  onPropertyNotify: (actor, spec) ->
    portMapping = @objectToPort[spec.name]
    return unless portMapping
    port = @outPorts[portMapping.portName]
    return unless port.isAttached()
    property = spec.name
    port.send(@convertPropertyIfNeeded(property, @getActor()[property]))
    port.disconnect()

  # Conversions

  pointToPointY: (value) ->
    return value.y

  pointToPointX: (value) ->
    return value.x

  pointXToPoint: (value) ->
    pivotPoint = @getActor().pivot_point
    pivotPoint.x = value
    return pivotPoint

  pointYToPoint: (value) ->
    pivotPoint = @getActor().pivot_point
    pivotPoint.y = value
    return pivotPoint

  objectToColor: (value) ->
    color = new Clutter.Color()
    for k, v of value
      color[k] = v
    return color

  colorToOjbect: (value) ->
    obj = {}
    props = [ 'red', 'green', 'blue', 'alpha' ]
    for k in props
      obj[k] = value[k] if value[k] != undefined
    return obj

  # Shutdown

  shutdown: () ->
    @destroyActor()

exports.getComponent = -> new ClutterActor
