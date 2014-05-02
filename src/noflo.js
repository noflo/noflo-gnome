const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Emulation = imports.emulation;
const Path = imports.path;
const Runtime = imports.runtime;

/* CoffeeScript compiler */

const CoffeeScript = imports.libs.coffeescript.CoffeeScript;

/**/

let NoFloContext = null;

/* Require() "emulation" */

let loadJavascriptFile = function(path) {
    let module = imports[path];
    return module;
};

let loadCoffeescriptFile = function(path) {
    let file = Gio.File.new_for_path(path + '.coffee');
    let [, coffeeSource] = file.load_contents(null);
    let javascriptSource = CoffeeScript.compile('' + coffeeSource,
                                                { bare: true });
    let module = eval('(function () { var exports = {};' +
                      javascriptSource + '; return exports; })()');

    return module;
};

let loadFile = function(path) {
    if (GLib.file_test(path + '.js', GLib.FileTest.IS_REGULAR))
        return loadJavascriptFile(path);
    if (GLib.file_test(path + '.coffee', GLib.FileTest.IS_REGULAR))
        return loadCoffeescriptFile(path);
    throw new Error("Can't load " + path);
};

let require = function(arg) {
    if (arg[0] != '/') {
        try {
            let module = NoFloContext.require(arg);
            if (module)
                return module;
        } catch (e) {
        }

        let libPath = Path.RESOURCE_DIR + '/js/libs/' + arg + '.js';
        if (GLib.file_test(libPath, GLib.FileTest.IS_REGULAR)) {
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

NoFloContext.require.alias("component-underscore/index.js", "underscore");
NoFloContext.require.alias("noflo-fbp/lib/fbp.js", "fbp");

const RuntimeBase = NoFloContext.require('noflo-runtime-base');
const Fbp = NoFloContext.require('fbp');

/**/

NoFloContext.require.register('noflo-gnome', function(exports, require, module) {
    exports.replaceMainloop = Runtime.replaceMainloop;
});
