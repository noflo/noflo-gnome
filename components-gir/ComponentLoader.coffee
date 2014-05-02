constructorComponent = require './ConstructorComponent'
GI = imports.gi.GIRepository

# TODO: Read from component.json
libs = [
  'Gtk',
  'GtkClutter'
]

exports = (loader, done) ->
  repo = GI.Repository.get_default()

  # List the constructors
  libs.forEach (lib) ->
    imports.gi[lib]
    infos = repo.get_n_infos lib
    for item in [0..infos]
      info = repo.get_info lib, item
      continue unless info.get_type() is GI.InfoType.OBJECT
      name = info.get_name()
      component = constructorComponent.getComponentForConstructor name, imports.gi[lib][name]
      loader.registerComponent lib.toLowerCase(), "Create#{name}", component

  do done if done
