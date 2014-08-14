noflo = require 'noflo'
Clutter = imports.gi.Clutter

valueToColor = (value) ->
  switch value
    when 0
      str = '#ffffff'
    when 2
      str = '#eee6db'
    when 4
      str = '#ece0c8'
    when 8
      str = '#efb27c'
    when 16
      str = '#fd9266'
    when 32
      str = '#f37d63'
    when 64
      str = '#f46042'
    when 128
      str = '#eacf76'
    when 256
      str = '#edcb67'
    when 512
      str = '#ecc85a'
    when 1024
      str = '#e7c257'
    when 2048
      str = '#e7bd4d'
    else
      str = '#e7bd4d'
  [s, color] = Clutter.Color.from_string str

  color.alpha = 255
  return color


exports.getComponent = () ->
  c = new noflo.Component

  c.inPorts.add 'map',
    datatype: 'array'
    description: 'Map to animate'
  c.inPorts.add 'duration',
    datatype: 'int'
    description: 'Duration of the animation in milliseconds'
    process: (event, payload) ->
      return unless event is 'data'
      c.duration = payload

  c.duration = 150

  c.outPorts.add 'map',
    datatype: 'array'

  c.TileAppearing = (actor, text, value, pos) ->
    text.text = "#{value}"
    actor.background_color = valueToColor value
    actor.translation_x = 100 * pos.x
    actor.translation_y = 100 * pos.y
    actor.set_pivot_point 0.5, 0.5
    actor.scale_x = actor.scale_y = 0.01

    actor.save_easing_state()
    actor.set_easing_duration c.duration
    actor.set_easing_mode Clutter.AnimationMode.LINEAR
    actor.scale_x = actor.scale_y = 1
    actor.restore_easing_state()

  c.TileMoving = (actor, text, value, pos) ->
    text.text = "#{value}"

    actor.save_easing_state()
    actor.set_easing_duration c.duration
    actor.set_easing_mode Clutter.AnimationMode.LINEAR
    actor.background_color = valueToColor value
    actor.translation_x = 100 * pos.x
    actor.translation_y = 100 * pos.y
    actor.restore_easing_state()

  c.TileDisappearing = (actor, text, value, pos) ->
    actor.set_pivot_point 0.5, 0.5

    actor.save_easing_state()
    actor.set_easing_duration c.duration
    actor.set_easing_mode Clutter.AnimationMode.LINEAR
    actor.scale_x = actor.scale_y = 0.01
    actor.opacity = 0
    actor.restore_easing_state()

  noflo.helpers.MapComponent c, (map, groups, out) ->
    for x in [0..(map.length - 1)]
      for y in [0..(map[0].length - 1)]
        actor = map[x][y].actor
        text = map[x][y].text
        value = map[x][y].value
        actor.width = actor.height = 100 unless actor.width == 100
        text.font_name = "Mono Bold 24px"

        pos =
          x: x
          y: y
        if map[x][y].init
          c.TileAppearing actor, text, value, pos
          map[x][y].init = false
        else if value is 0
          c.TileDisappearing actor, text, value, pos
        else
          c.TileMoving actor, text, value, pos

        #log "#{x}x#{y} -> #{} - #{actor.translation_x}x#{actor.translation_y} #{actor} anim=#{anim} value=#{value}"
    out.send map
  ,
    inPort: 'map'
    outPort: 'map'

  c
