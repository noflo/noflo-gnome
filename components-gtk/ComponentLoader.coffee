GladeConstructorComponent = require './GladeConstructorComponent'
Gio = imports.gi.Gio
Runtime = imports.runtime;
Utils = imports.utils

exports = (loader, done) ->
  manifest = Runtime.getApplicationManifest()
  do done unless manifest.ui
  for ui in manifest.ui
    path = Utils.resolvePath('local://' + ui)
    file = Gio.File.new_for_path path
    log "Available glade ui file at #{file.get_path()}"
    name = file.get_basename().replace(/\.glade$/, '').replace(/[^a-zA-Z\/\-0-9_]/g, '')
    component = GladeConstructorComponent.getComponentForFile file
    loader.registerComponent 'gtk-builder', name, component
  do done if done
