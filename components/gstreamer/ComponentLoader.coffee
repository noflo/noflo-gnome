GstreamerComponentLoader = require './GstreamerComponentLoader'
Runtime = imports.runtime;

isGstreamerIncluded = () ->
  manifest = Runtime.getApplicationManifest()
  if manifest.libraries?
    for lib in manifest.libraries
      return true if lib is 'Gst'
  return false

exports = (loader, done) ->
  manifest = Runtime.getApplicationManifest()
  GstreamerComponentLoader.load loader if isGstreamerIncluded()
  done() if done
  return
