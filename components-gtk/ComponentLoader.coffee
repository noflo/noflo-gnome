GladeConstructorComponent = require './GladeConstructorComponent'
Gio = imports.gi.Gio
Utils = imports.utils

exports = (loader, done) ->
  Utils.forEachInDirectory Gio.File.new_for_path('.'), (child) =>
    return unless child.get_path().match(/.*\.glade/)
    log "Available glade ui file at #{child.get_path()}"
    name = child.get_basename().replace('\.glade', '').replace(/[^a-zA-Z\/\-0-9_]/g, '')
    component = GladeConstructorComponent.getComponentForFile child
    loader.registerComponent 'gtk-builder', name, component
  do done if done
