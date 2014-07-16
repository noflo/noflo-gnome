DbusComponentFactory = require './DbusComponentFactory'
Gio = imports.gi.Gio
Runtime = imports.runtime
Utils = imports.utils

loadInterface = (loader, iface) ->
  if iface.properties and iface.properties.length > 0
    cmp = DbusComponentFactory.getComponentOutputProperties iface
    loader.registerComponent 'dbus', "#{iface.name}-rprops", cmp
    cmp = DbusComponentFactory.getComponentInputProperties iface
    loader.registerComponent 'dbus', "#{iface.name}-wprops", cmp
  if iface.methods and iface.methods.length > 0
    for i in [0..(iface.methods.length - 1)]
      method = iface.methods[i]
      cmp = DbusComponentFactory.getComponentMethod iface, method
      loader.registerComponent 'dbus', "#{iface.name}.#{method.name}", cmp

loadInterfaces = (loader, ifaces) ->
  for i in [0..(ifaces.length - 1)]
    loadInterface loader, ifaces[i]

exports.load = (loader, manifest) ->
  return unless manifest.dbus
  for iface in manifest.dbus
    vpath = 'local://' + iface.file
    try
      content = Utils.loadTextFileContent Utils.resolvePath vpath
      info = Gio.DBusNodeInfo.new_for_xml content
      loadInterfaces loader, info.interfaces
    catch e
      log "Cannot load #{vpath} : #{e.message}"
