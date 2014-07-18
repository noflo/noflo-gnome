DbusComponentLoader = require './DbusComponentLoader'
Runtime = imports.runtime;

exports = (loader, done) ->
  manifest = Runtime.getApplicationManifest()
  DbusComponentLoader.load loader, manifest
  done() if done
  return
