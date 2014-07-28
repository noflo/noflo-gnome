noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'map',
    datatype: 'array'
    required: yes
  c.inPorts.add 'direction',
    datatype: 'string'
    required: yes

  c.outPorts.add 'map',
    datatype: 'array'
    process: (event, payload) ->
      return unless event is 'data'
      c.squashCounter = 0
      return
  c.outPorts.add 'modified',
    datatype: 'bang'
  c.outPorts.add 'unmodified',
    datatype: 'bang'

  noflo.helpers.WirePattern c,
    in: 'direction'
    params: ['map']
    out: 'map'
    forwardGroups: true
  , (data, groups, out) ->
    c.squash data, c.params.map
    out.send c.params.map
    if @squashCount > 0
      @outPorts.modified.send true
      @outPorts.modified.disconnect()
    else
      @outPorts.unmodified.send true
      @outPorts.unmodified.disconnect()

  c.generateMove = (map, sx, sy, dx, dy) ->
    map[dx][dy].value = map[sx][sy].value
    map[sx][sy].value = 0
    tmpActor = map[dx][dy].actor
    map[dx][dy].actor = map[sx][sy].actor
    map[sx][sy].actor = tmpActor
    tmpActor = map[dx][dy].text
    map[dx][dy].text = map[sx][sy].text
    map[sx][sy].text = tmpActor
    @squashCount += 1

  c.generateSquash = (map, sx, sy, dx, dy) ->
    map[dx][dy].value += map[sx][sy].value
    map[sx][sy].value = 0
    map[dx][dy].squashCounter = @squashCounter
    tmpActor = map[dx][dy].actor
    map[dx][dy].actor = map[sx][sy].actor
    map[sx][sy].actor = tmpActor
    tmpActor = map[dx][dy].text
    map[dx][dy].text = map[sx][sy].text
    map[sx][sy].text = tmpActor
    @squashCount += 1

  c.squash = (direction, map) ->
    @squashCount = 0
    @squashCounter += 1
    switch direction
      when 'left'
        #log "squashing left"
        for y in [0..(map[0].length - 1)]
          for x in [0..(map.length - 1)]
            @squashX map, x, y, [x..0], Math.min
      when 'right'
        #log "squashing right"
        for y in [0..(map[0].length - 1)]
          for x in [(map.length - 1)..0]
            @squashX map, x, y, [x..(map.length - 1)], Math.max
      when 'up'
        #log "squashing up"
        for x in [0..(map.length - 1)]
          for y in [0..(map[0].length - 1)]
            @squashY map, x, y, [y..0], Math.min
      when 'down'
        #log "squashing down"
        for x in [0..(map.length - 1)]
          for y in [(map.length - 1)..0]
            @squashY map, x, y, [y..(map.length - 1)], Math.max

  c.squashX = (map, x, y, range, func) ->
    return if map[x][y].value == 0
    newPos =
      x: x
      y: y
    for ix in range
      continue if ix is x
      #log "trying #{ix}x#{y} - #{x}x#{y}"
      if map[ix][y].value == 0
        #log "->moving #{x} to #{ix}"
        newPos.x = func(newPos.x, ix)
      else if map[ix][y].value == map[x][y].value and map[ix][y].squashCounter != @squashCounter
        #log "->squashing #{x} to #{ix}"
        newPos.x = func(newPos.x, ix)
        @generateSquash map, x, y, newPos.x, newPos.y
        return
      else
        break
    return if x == newPos.x and y == newPos.y
    @generateMove map, x, y, newPos.x, newPos.y
    return

  c.squashY = (map, x, y, range, func) ->
    return if map[x][y].value == 0
    newPos =
      x: x
      y: y
    for iy in range
      continue if iy is y
      #log "trying #{x}x#{iy} - #{x}x#{y}"
      if map[x][iy].value == 0
        #log "->moving #{y} to #{iy}"
        newPos.y = func(newPos.y, iy)
      else if map[x][iy].value == map[x][y].value and map[x][iy].squashCounter != @squashCounter
        #log "->squashing #{y} to #{iy}"
        newPos.y = func(newPos.y, iy)
        @generateSquash map, x, y, newPos.x, newPos.y
        return
      else
        break
    return if x == newPos.x and y == newPos.y
    @generateMove map, x, y, newPos.x, newPos.y
    return

  c
