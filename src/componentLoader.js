const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Lang = imports.lang;
const Mainloop = imports.mainloop;
const Utils = imports.utils;
const NoFlo = imports.noflo;
const Fbp = require('fbp');

/* Module listing */

let getModuleAtPath = function(vpath) {
    let path = Utils.resolvePath(vpath);

    if (!GLib.file_test(path, GLib.FileTest.IS_DIR))
        return null;

    let manifestPath = path + '/component.json';
    if (!GLib.file_test(manifestPath, GLib.FileTest.IS_REGULAR))
        return null;

    let file = Gio.File.new_for_path(manifestPath);
    let [, manifestContent] = file.load_contents(null);
    let manifest;

    try {
        module = JSON.parse('' + manifestContent);
        module.vpath = vpath;
        module.path = path;
    } catch (e) {
        return null;
    }

    /* Quick sanity check */
    if (!module.name ||
        !module.noflo)
        return null;

    return module;
};

let getModulesInPath = function(vpath) {
    let modules = {};
    let path = Utils.resolvePath(vpath);

    if (!GLib.file_test(path, GLib.FileTest.IS_DIR))
        return modules;

    Utils.forEachInDirectory(Gio.File.new_for_path(path), function(child) {
        let module = getModuleAtPath(Utils.buildPath(vpath,
                                                     child.get_basename()));

        if (module)
            modules[module.name] = module;
    });

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
    self.listCallbacks = [];

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

    let generateComponentInstance = function(vpath) {
        return function(metadata) {
            try {
                let implementation = require(vpath);
                let instance = implementation.getComponent(metadata);
                return instance;
            } catch (e) {
                log('Failed to load : ' + vpath);
                throw e;
            }
        };
    };

    let generateGraphLoader = function(vpath) {
        return function() {
            try {
                let path = Utils.resolvePath(vpath);
                let source = Utils.loadTextFileContent(path);
                if (path.indexOf('.fbp'))
                    source = Fbp.parse(source);
                else
                    source = JSON.parse(source);
                return source;
            } catch (e) {
                log('Failed to load : ' + vpath);
                throw e;
            }
            return '';
        };
    };

    let generateComponentCodeLoader = function(path) {
        return function() {
            let file = Gio.File.new_for_path(Utils.resolvePath(path));
            let [, code] = file.load_contents(null);
            return '' + code;
        };
    };

    let getComponentFullPath = function(module, component) {
        return module.vpath + '/' + module.noflo.components[component];
    };

    let getGraphFullPath = function(module, component) {
        return module.vpath + '/' + module.noflo.graphs[component];
    };

    let getComponentRequirePath = function(module, component) {
        return removeExtension(getComponentFullPath(module, component));
    };

    self.listComponents = function(callback) {
        // List is built already
        if (self.builtList) {
            callback(self.components);
            return;
        }

        self.listCallbacks.push(callback);

        // Building list
        if (self.buildingList)
            return;

        self.buildingList = true;

        Mainloop.timeout_add(0, Lang.bind(this, function() {
            let modules = getModules(self.options.paths);
            self.components = {};
            for (let moduleName in modules) {
                let module = modules[moduleName];

                // Components
                for (let componentName in module.noflo.components) {
                    let path = normalizeName(moduleName + '/' + componentName);
                    let fullPath = getComponentFullPath(module, componentName);
                    let requirePath = removeExtension(fullPath);
                    self.components[path] = {
                        isGraph: false,
                        module: module,
                        moduleName: normalizeName(moduleName),
                        name: componentName,
                        create: generateComponentInstance(requirePath),
                        getCode: generateComponentCodeLoader(fullPath),
                        language: Utils.guessLanguageFromFilename(fullPath),
                    };
                }

                // Graphs
                for (let graphName in module.noflo.graphs) {
                    let path = normalizeName(moduleName + '/' + graphName);
                    let fullPath = getGraphFullPath(module, graphName);
                    self.components[path] = {
                        isGraph: true,
                        module: module,
                        moduleName: normalizeName(moduleName),
                        name: graphName,
                        getCode: generateGraphLoader(fullPath),
                    };
                }

                // Loaders
                if (module.noflo.loader) {
                    let path = module.vpath + '/' + module.noflo.loader;
                    path = removeExtension(path);
                    let loader = require(path);
                    loader(self);
                }
            }

            let callbacks = self.listCallbacks;
            self.listCallbacks = [];
            self.buildingList = false;
            self.builtList = true;
            for (let i in callbacks)
                callbacks[i](self.components);

            return false;
        }));
    };

    self.load = function(name, callback, delayed, metadata) {
        let item = self.components[name];
        if (!item)
            throw new Error('Component ' + name + ' not available');

        if (item.isGraph)
            self.loadGraph(item, delayed, metadata, callback);
        else
            self.loadComponent(item, metadata, callback);
    };

    self.loadComponent = function(item, metadata, callback) {
        log('loadComponent ' + item.name);
        Mainloop.timeout_add(0, Lang.bind(this, function() {
            callback(item.create(metadata));
            return false;
        }));
    }

    self.loadGraph = function(item, delayed, metadata, callback) {
        log('loadGraph ' + item.name);
        let graphSocket = NoFlo.internalSocket.createSocket();
        let graph = NoFlo.Graph.getComponent(metadata);
        graph.loader = self;

        if (delayed) {
            delaySocket = NoFlo.internalSocket.createSocket();
            graph.inPorts.start.attach(delaySocket);
        }

        graph.inPorts.graph.attach(graphSocket);
        graphSocket.send(item.getCode());
        graphSocket.disconnect();
        graph.inPorts.remove('graph');
        graph.inPorts.remove('start');
        graph.setIcon('sitemap');
        callback(graph);
    };

    self.registerComponent = function(packageId, name, constructor) {
        self.components[packageId + '/' + name] = {
            module: packageId,
            name: name,
            create: constructor,
            language: 'javascript'
        };
        log('registerComponent ' + packageId + ' / ' + name);
    };

    self.registerGraph = function(packageId, name, gPath, callback) {
        throw new Error('registerGraph ' + packageId + ' / ' + name);
    };

    self.setSource = function(packageId, name, source, language, callback) {
        log('setSource ' + packageId + ' / ' + name);
    };

    self.getSource = function(name, callback) {
        log('getting code for ' + name);
        let item = self.components[name];
        if (item && !item.isGraph && item.getCode) {
            try {
                callback(null,
                         { name: self.components[name].name,
                           library: self.components[name].moduleName,
                           code: self.components[name].getCode(),
                           language: self.components[name].language
                         });
            } catch (e) {
                log('error loading ' + name + ' : ' + e.message);
                callback(new Error("Cannot load source code for " +
                                   name + " : " + e.message));
            }
        } else {
            log('no source code for ' + name);
            callback(new Error("No source code available for " + name));
        }
    };
};
