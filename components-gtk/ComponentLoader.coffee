GladeConstructorComponent = require './GladeConstructorComponent'
Gio = imports.gi.Gio
Runtime = imports.runtime;
Utils = imports.utils

exports = (loader, done) ->
  manifest = Runtime.getApplicationManifest()
  do done unless manifest.ui
  for ui in manifest.ui
    try
      path = Utils.resolvePath('local://' + ui.file)
      file = Gio.File.new_for_path path
      name = file.get_basename().replace(/\.glade$/, '').replace(/[^a-zA-Z\/\-0-9_]/g, '')
      component = GladeConstructorComponent.getComponentForFile file, ui.additionals
      loader.registerComponent 'gtk-builder', name, component
    catch e
      log "Fail to load UI file: #{e.message}"
  do done if done
