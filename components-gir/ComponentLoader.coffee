constructorComponent = require './ConstructorComponent'
GI = imports.gi.GIRepository
Runtime = imports.runtime;

exports = (loader, done) ->
  repo = GI.Repository.get_default()
  manifest = Runtime.getApplicationManifest()

  do done unless manifest and manifest.libraries

  # List the constructors
  manifest.libraries.forEach (lib) ->
    imports.gi[lib]
    infos = repo.get_n_infos lib
    for item in [0..infos]
      info = repo.get_info lib, item
      continue unless info.get_type() is GI.InfoType.OBJECT
      name = info.get_name()
      component = constructorComponent.getComponentForConstructor name, imports.gi[lib][name]
      loader.registerComponent lib.toLowerCase(), "Create#{name}", component

  do done if done
  null
