constructorComponent = require './ConstructorComponent'
GI = imports.gi.GIRepository
Runtime = imports.runtime;

exports = (loader, done) ->
  repo = GI.Repository.get_default()
  manifest = Runtime.getApplicationManifest()

  unless manifest and manifest.libraries
    do done if done
    return

  # List the constructors
  manifest.libraries.forEach (lib) ->
    libRepo = imports.gi[lib]
    if typeof libRepo.init is 'function'
      libRepo.init(null, null)
    infos = repo.get_n_infos lib
    for item in [0..infos]
      info = repo.get_info lib, item
      continue unless info.get_type() is GI.InfoType.OBJECT
      name = info.get_name()
      try
        component = constructorComponent.getComponentForConstructor name, imports.gi[lib][name]
        loader.registerComponent lib.toLowerCase(), "Create#{name}", component
      catch e

  do done if done
  return
