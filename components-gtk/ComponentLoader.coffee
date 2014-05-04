GladeConstructorComponent = require './GladeConstructorComponent'
Gio = imports.gi.Gio
Utils = imports.utils

exports = (loader, done) ->
  Utils.forEachInDirectory Gio.File.new_for_path('.'), (child) =>
    path = child.get_path()
    return unless path.match(/.*\.glade$/) or path.match(/.*\.ui$/)
    log "Available glade ui file at #{child.get_path()}"
    name = child.get_basename().replace('\.glade', '').replace(/[^a-zA-Z\/\-0-9_]/g, '')
    component = GladeConstructorComponent.getComponentForFile child
    loader.registerComponent 'gtk-builder', name, component
  do done if done
