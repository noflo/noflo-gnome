const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Lang = imports.lang;
const Mainloop = imports.mainloop;
const Utils = imports.utils;

/* Module listing */

let getModuleAtPath = function(path) {
    if (!GLib.file_test(path, GLib.FileTest.IS_DIR))
        return null;

    let manifestPath = path + '/component.json';
    if (!GLib.file_test(manifestPath, GLib.FileTest.IS_REGULAR))
        return null;

    let file = Gio.File.new_for_path(manifestPath);
    let [, manifestContent] = file.load_contents(null);
    let manifest;

    try {
        manifest = JSON.parse('' + manifestContent);
        manifest.path = path;
    } catch (e) {
        return null;
    }

    /* Quick sanity check */
    if (!manifest.name ||
        !manifest.noflo)
        return null;

    return manifest;
};

let getModulesInPath = function(path) {
    let modules = {};

    if (!GLib.file_test(path, GLib.FileTest.IS_DIR))
        return modules;

    let dir = Gio.File.new_for_path(path);
    let enumerator = dir.enumerate_children('*', Gio.FileQueryInfoFlags.NONE, null);
    let fileInfo;
    while ((fileInfo = enumerator.next_file(null)) != null) {
        let child = enumerator.get_child(fileInfo);
        let module = getModuleAtPath(child.get_path());

        if (module)
            modules[module.name] = module;
    }
    enumerator.close(null);

    return modules;
};

let getModules = function(paths) {
    let modules = {};
    for (let i in paths) {
        Utils.mergeProps(modules, getModulesInPath(paths[i]));
    }
    return modules;
};

/* Component loader to be injected into the runtime base */

let ComponentLoader = function(options) {
    let self = this;

    /* Ensure with have valid options */
    self.options = options;
    if (!self.options)
        self.options = { paths: [ '.' ] };
    if (!self.options.path)
        self.options.path = ['.'];

    self.components = {};

    let logFunc = function(name) {
        log('calling : ' +  name);
    };

    let normalizeName = function(name) {
        return name.replace('noflo-', '');
    };

    let removeExtension = function(path) {
        let ret = path.replace(/\.coffee$/, '');
        return ret.replace(/\.js$/, '');
    };

    self.listComponents = function(callback) {
        Mainloop.timeout_add(0, Lang.bind(this, function() {
            let modules = getModules(self.options.paths);
            self.components = {};
            for (let i in modules) {
                let module = modules[i];
                for (let j in module.noflo.components) {
                    let path = normalizeName(module.name + '/' + j);
                    self.components[path] = {
                        module: module,
                        component: j,
                    };
                }
            }
            callback(self.components);
            return false;
        }));
    };

    self.load = function(name, callback, delayed, metadata) {
        if (!self.components[name])
            throw new Error('Component ' + name + ' not available');

        Mainloop.timeout_add(0, Lang.bind(this, function() {
            let compDescr = self.components[name];
            let path = compDescr.module.path + '/' +
                compDescr.module.noflo.components[compDescr.component];
            path = removeExtension(path);
            //log('loading ' + name + ' from ' + path);
            let implementation = require(path);
            let instance = implementation.getComponent(metadata);
            callback(instance);

            return false;
        }));
    };

    self.loadGraph = function(name, component, callback, delayed, metadata) {
        log('loadGraph ' + name);
    };

    self.setIcon = function(name, instance) {
        log('setIcon ' + name);
    };

    self.getLibraryIcon = function(prefix) {
        log('getLibraryIcon ' + prefix);
    };

    self.registerComponent = function(packageId, name, cPath, callback) {
        log('registerComponent ' + packageId + ' / ' + name);
    };

    self.registerGraph = function(packageId, name, gPath, callback) {
        log('registerGraph ' + packageId + ' / ' + name);
    };

    self.setSource = function(packageId, name, source, language, callback) {
        log('setSource ' + packageId + ' / ' + name);
    };

    self.getSource = function(name, callback) {
        log('getSource ' + name);
    };
};
