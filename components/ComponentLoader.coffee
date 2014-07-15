DbusComponentLoader = require './DbusComponentLoader'
Runtime = imports.runtime;

exports = (loader, done) ->
  manifest = Runtime.getApplicationManifest()
  DbusComponentLoader.load loader, manifest
  do done if done
