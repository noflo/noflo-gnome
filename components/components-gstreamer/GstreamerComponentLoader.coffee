Gst = imports.gi.Gst
GstComponentFactory = require './GstreamerComponentFactory'

exports.load = (loader) ->
  Gst.init null, null

  registry = Gst.Registry.get()
  plugins = registry.get_plugin_list()
  for plugin in plugins
    features = registry.get_feature_list_by_plugin plugin.get_name()
    for feature in features
      continue unless feature instanceof Gst.ElementFactory
      name = feature.get_name()
      cmp = GstComponentFactory.getComponentFromFactory name, feature
      loader.registerComponent 'gstreamer', name, cmp
