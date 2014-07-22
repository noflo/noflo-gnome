const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Lang = imports.lang;
const Mainloop = imports.mainloop;
const CodeWriter = imports.codeWriter;
const Utils = imports.utils;
const NoFlo = imports.noflo;
const Fbp = require('fbp');

let normalizeName = function(name) {
    return name.replace('noflo-', '');
};

/* Module listing */

let getModuleAtPath = function(vpath, alternativeFile) {
    let path = Utils.resolvePath(vpath);

    if (!GLib.file_test(path, GLib.FileTest.IS_DIR))
        return null;

    let manifestPath = path + (alternativeFile ? alternativeFile : '/component.json');
    if (!GLib.file_test(manifestPath, GLib.FileTest.IS_REGULAR))
        return null;

    let file = Gio.File.new_for_path(manifestPath);
    let [, manifestContent] = file.load_contents(null);
    let manifest;

    let module;
    try {
        module = JSON.parse('' + manifestContent);
        module.vpath = vpath;
        module.path = path;
        module.normalizedName = normalizeName(module.name);
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

    Utils.forEachInDirectory(Gio.File.new_for_path(path), false, function(child) {
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
    if (!self.options || !self.options.paths)
        self.options = { paths: [ 'library://components' ] };

    self.applicationName = null;
    self.mainGraphName = null;
    self.mainGraph = null;
    self.modules = {};
    self.components = {};

    let removeExtension = function(path) {
        let ret = path.replace(/\.coffee$/, '');
        return ret.replace(/\.js$/, '');
    };

    /* Components */

    let generateComponentInstance = function(vpath) {
        return function(metadata) {
            if (!this.implementation)
                this.implementation = require(vpath);
            let instance = this.implementation.getComponent(metadata);
            return instance;
        };
    };

    let generateComponentCodeLoader = function(path) {
        return function() {
            let file = Gio.File.new_for_path(Utils.resolvePath(path));
            let [, code] = file.load_contents(null);
            return '' + code;
        };
    };

    /* Graphs */

    let generateGraphCodeLoader = function(vpath) {
        return function() {
            try {
                let path = Utils.resolvePath(vpath);
                let source = Utils.loadTextFileContent(path);
                return source;
            } catch (e) {
                log('Failed to load graph : ' + vpath);
                throw e;
            }
            return null;
        };
    };

    let generateGraphDefinition = function(vpath) {
        return function() {
            try {
                let path = Utils.resolvePath(vpath);
                let source = Utils.loadTextFileContent(path);
                let def;
                if (path.indexOf('.fbp') >= 0)
                    def = Fbp.parse(source);
                else
                    def = JSON.parse(source);
                def.properties = {
                    name: this.name,
                    id: this.name,
                };
                return def;
            } catch (e) {
                log('Failed to load graph definition : ' + vpath + ' : ' + e.message);
                throw e;
            }
            return null;
        };
    };

    let generateGraphLoader = function() {
        return function(metadata) {
            let graph = NoFlo.NoFlo.graph.loadJSON(
                this.getDefinition(),
                function(a) { return a; },
                metadata);
            graph.baseDir = self.options.baseDir;
            return graph;
        };
    };

    /**/

    let getComponentFullPath = function(module, component) {
        return module.vpath + '/' + module.noflo.components[component];
    };

    let getGraphFullPath = function(module, component) {
        return module.vpath + '/' + module.noflo.graphs[component];
    };

    let getComponentRequirePath = function(module, component) {
        return removeExtension(getComponentFullPath(module, component));
    };

    /**/

    self._loadModule = function(module) {
        // Avoid circular dependencies
        if (module.loading || module.loaded)
            return;
        module.loading = true;

        // Try to load dependencies first
        if (module.dependencies) {
            for (let depName in module.dependencies) {
                let dep = /[^\/]+\/(.*)/.exec(depName);
                if (dep && dep[1] && self.modules[dep[1]])
                    self._loadModule(self.modules[dep[1]]);
            }
        }

        // Components
        for (let componentName in module.noflo.components) {
            let path = normalizeName(module.name + '/' + componentName);
            let fullPath = getComponentFullPath(module, componentName);
            let requirePath = removeExtension(fullPath);
            self.components[path] = {
                path: fullPath,
                isGraph: false,
                module: module,
                moduleName: normalizeName(module.name),
                name: componentName,
                create: generateComponentInstance(requirePath),
                getCode: generateComponentCodeLoader(fullPath),
                language: Utils.guessLanguageFromFilename(fullPath),
            };
        }

        // Graphs
        for (let graphName in module.noflo.graphs) {
            let path = normalizeName(module.name + '/' + graphName);
            let fullPath = getGraphFullPath(module, graphName);
            let component = {
                path: fullPath,
                isGraph: true,
                module: module,
                moduleName: normalizeName(module.name),
                name: graphName,
                getDefinition: generateGraphDefinition(fullPath),
                getCode: generateGraphCodeLoader(fullPath),
                create: generateGraphLoader(path),
                language: 'json',
            };

            if (module.name == self.applicationName &&
                graphName == self.mainGraphName)
                self.mainGraph = component;
            else
                self.components[path] = component;
        }

        // Loaders
        if (module.noflo.loader) {
            let path = module.vpath + '/' + module.noflo.loader;
            path = removeExtension(path);
            let loader = require(path);
            loader(self);
        }

        delete module.loading;
        module.loaded = true;
    };

    self.loadModules = function() {
        // Load libray modules
        self.modules = getModules(self.options.paths);
        // Load application components/graphs
        let appModule = getModuleAtPath('local://', 'manifest.json');
        self.applicationName = appModule.name;
        self.mainGraphName = appModule.noflo.main;
        self.modules[appModule.name] = appModule;

        for (let moduleName in self.modules) {
            self._loadModule(self.modules[moduleName]);
            //log('loading ' + moduleName);
        }
    };

    self.listComponents = function(callback) {
        callback(self.components);
    };

    self.load = function(name, callback, delayed, metadata) {
        //log('load name=' + name);
        let item = self.components[name];
        if (!item)
            throw new Error('Component ' + name + ' not available');

        if (item.isGraph)
            self._loadGraph(item, delayed, metadata, callback);
        else
            self._loadComponent(item, metadata, callback);
    };

    self._loadComponent = function(item, metadata, callback) {

        Mainloop.timeout_add(0, Lang.bind(this, function() {
            try {
                callback(item.create(metadata));
            } catch (e) {
                log('Cannot load component ' + item.name +
                    ' ' + item.path + ' : ' + e.message);
            }
            return false;
        }));
    }

    self._loadGraph = function(item, delayed, metadata, callback) {
        //log('loadGraph ' + item.name);
        let graph = NoFlo.Graph.getComponent(metadata);
        let graphSocket = NoFlo.internalSocket.createSocket();
        graph.loader = self;
        graph.baseDir = self.options.baseDir

        if (delayed) {
            let delaySocket = NoFlo.internalSocket.createSocket();
            graph.inPorts.start.attach(delaySocket);
        }

        graph.inPorts.graph.attach(graphSocket);

        try {
            graphSocket.send(item.create(metadata));
            graphSocket.disconnect();
            graph.inPorts.remove('graph');
            graph.inPorts.remove('start');
            graph.setIcon('sitemap');
            callback(graph);
        } catch (e) {
            log('Cannot load graph ' + item.name +
                ' ' + item.path + ' : ' + e.message);
        }
    };

    self.registerComponent = function(packageId, name, constructor) {
        let path = (packageId != '') ? (packageId + '/' + name) : name;

        if (self.components[path]) {
            log('Dismissing registration for ' + path);
            return;
        }

        self.components[path] = {
            path: 'unknown',
            module: null,
            name: name,
            create: constructor,
            getCode: function() { return ''; },
            language: 'javascript'
        };
        log('registerComponent ' + packageId + ' / ' + name);
    };

    self.registerGraph = function(packageId, name, gPath, callback) {
        log('----------> registerGraph ' + packageId + ' / ' + name);
        throw new Error('registerGraph ' + packageId + ' / ' + name);
    };

    /**/

    self.setSource = function(packageId, name, source, language, callback) {
        log('setSource ' + packageId + ' / ' + name);
    };

    self.getSource = function(name, callback) {
        let item = self.components[name];
        if (item) {
            try {
                //log(JSON.stringify(item.getCode()));
                callback(null, { name: item.name,
                                 library: item.moduleName,
                                 code: item.getCode(),
                                 language: item.language
                               });
            } catch (e) {
                log('error loading ' + name + ' : ' + e.message);
                callback(new Error("Cannot load source code for " +
                                   name + " : " + e.message));
            }
        } else {
            log('Unknown component ' + name);
            callback(new Error('Unknown component ' + name));
        }
    };

    self.getGraphDefinition = function(name, callback) {
        let item = self.components[name];

        if (item) {
            try {
                let descr = item.getDefinition();
                callback(null, descr);
            } catch (e) {
                log('error loading ' + name + ' : ' + e.message);
                callback(new Error("Cannot load definition for " +
                                   name + " : " + e.message));
            }
        } else {
            log('Unknown graph ' + name);
            callback(new Error('Unknown graph ' + name));
        }
    };

    /**/

    self.getComponentModule = function(name) {
        let item = self.components[name];
        if (item)
            return item.module;
        return null;
    };

    self.getComponentCode = function(name) {
        //log('Looking up component : ' + name);
        let item = self.components[name];
        if (item)
            return item.getCode();
        return null;
    };

    /**/

    self.save = function(runtime) {
        log('Saving graphs!');
        for (let i in runtime.graph.graphs) {
            let graph = runtime.graph.graphs[i];
            CodeWriter.writeGraph(graph);
        }
    };

    self._saveCb = function() {
        self.save(self._runtime);
        self._saveTimeout = null;
        return false;
    };

    self._graphUpdate = function() {
        if (self._saveTimeout)
            Mainloop.source_remove(self._saveTimeout);
        self._saveTimeout =
            Mainloop.timeout_add(1000, Lang.bind(self, self._saveCb));
    };

    self.autosave = function(runtime) {
        log('autosave!');
        self._runtime = runtime;
        for (let i in runtime.graph.graphs) {
            let graph = runtime.graph.graphs[i];
            log('listening on ' + graph.name);
            graph.on('endTransaction', Lang.bind(self, self._graphUpdate));
        }
   };

    /**/

    self._installGraphs = function(runtime) {
        for (let graphName in self.modules[self.applicationName].noflo.graphs) {
            let path = self.applicationName + '/' + graphName;
            let component = self.components[path];

            if (component)
                runtime.graph.registerGraph(graphName, component.create());
        }
        runtime.graph.registerGraph(self.mainGraphName,
                                    self.mainGraph.create());
    };

    self._installNetwork = function(runtime) {
        let path = self.mainGraphName;
        let component = self.components[path];

        runtime.network.initNetwork(runtime.graph.graphs[path],
                                    { graph: path, },
                                    '');
    };

    /**/

    self.install = function(runtime) {
        self.loadModules();
        self._installGraphs(runtime);
        self._installNetwork(runtime);
    };
};
