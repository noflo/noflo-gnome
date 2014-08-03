noflo = require 'noflo'
Gst = imports.gi.Gst

exports.getComponentFromFactory = (name, factory) ->
  (metadata) ->
    c = new noflo.Component
    c.description = "#{name}: #{factory.get_metadata 'long-name'}"

    c.gstFactory = factory

    element = factory.create null

    addInPort = (pad) ->
      #log "\tin: #{pad.get_name()}"
      c.inPorts.add pad.get_name(),
        datatype: 'object'

    addOutPort = (pad) ->
      #log "\tout: #{pad.get_name()}"
      c.outPorts.add pad.get_name(),
        datatype: 'object'

    # Sinks
    iter = element.iterate_sink_pads()
    r = Gst.IteratorResult.OK
    while r == Gst.IteratorResult.OK
      [r, v] = iter.next()
      addInPort v if r == Gst.IteratorResult.OK

    # Srcs
    iter = element.iterate_src_pads()
    r = Gst.IteratorResult.OK
    while r == Gst.IteratorResult.OK
      [r, v] = iter.next()
      addOutPort v if r == Gst.IteratorResult.OK

    c
