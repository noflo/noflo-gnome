const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const CodeLoader = imports.codeLoader;
const Emulation = imports.emulation;
const Path = imports.path;
const Runtime = imports.runtime;
const Utils = imports.utils;

/**/

let NoFloContext = null;

/* Require() "emulation" */

let loadFile = function(vpath) {
    //log('load file ' + vpath);
    if (Utils.isPathRegular(Runtime.resolvePath(vpath + '.js')))
        return CodeLoader.loadJavascript(vpath);
    if (Utils.isPathRegular(Runtime.resolvePath(vpath + '.coffee')))
        return CodeLoader.loadCoffeescript(vpath);
    throw new Error("Can't load " + vpath);
};

let require = function(arg) {
    if (arg[0] != '/') {
        try {
            let module = NoFloContext.require(arg);
            if (module)
                return module;
        } catch (e) {
        }

        let libPath = 'internal://libs/' + arg + '.js';
        if (Utils.isPathRegular(libPath)) {
            let lib = imports.libs[arg];
            return lib;
        }
    }

    let getPaths = function() {
        if (!window._requirePaths)
            window._requirePaths = [];
        return window._requirePaths;
    };

    let pushPath = function(path) {
        getPaths().push(path);
    };

    let popPath = function() {
        getPaths().pop();
    };

    let getGlobalPath = function() {
        let r = '';
        let paths = getPaths();
        for (let i in paths)
            r += paths[i] + '/';
        return r;
    };

    let path = getGlobalPath() + arg;
    let parentPath = GLib.path_get_dirname(arg);
    if (parentPath == '' || parentPath == '.')
        parentPath = null;
    if (parentPath) pushPath(parentPath);
    let module;
    try {
        module = loadFile(path);
    } catch (e) {
        throw e;
    } finally {
        if (parentPath) popPath();
    }

    return module;
};
window.require = require;

/* NoFlo Runtime */

NoFloContext = imports.libs['noflo-runtime-base'];
Emulation.inject();

const NoFlo = NoFloContext.require('noflo');

NoFloContext.require.alias("jashkenas-underscore/underscore.js", "underscore");
NoFloContext.require.alias("noflo-fbp/lib/fbp.js", "fbp");
NoFloContext.require.alias("noflo-noflo/src/components/Graph.js", "Graph");

const RuntimeBase = NoFloContext.require('noflo-runtime-base');
const Graph = NoFloContext.require('noflo-noflo/src/components/Graph.js');
const internalSocket = NoFlo.internalSocket;

/**/

NoFloContext.require.register('noflo-gnome', function(exports, require, module) {
    exports.replaceMainloop = Runtime.replaceMainloop;
});
