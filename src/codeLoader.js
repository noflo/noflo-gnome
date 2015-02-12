const Gio = imports.gi.Gio;
const Runtime = imports.runtime;
const Utils = imports.utils;

const CoffeeScript = imports.libs.coffeescript.CoffeeScript;

//
let compileCoffeeSource = function(source) {
    return CoffeeScript.compile(source, { bare: true });
};

// from: GFile
// to: GFile
let compileFile = function(to, from) {
    let [, coffeeSource] = from.load_contents(null);
    let javascriptSource = compileCoffeeSource('' + coffeeSource);

    // Compilation cache
    try {
        to.get_parent().make_directory_with_parents(null);
    } catch (e) {
    }
    to.replace_contents(javascriptSource,
                        null,
                        false,
                        Gio.FileCreateFlags.REPLACE_DESTINATION,
                        null,
                        null);

    let module = null;
    try {
        module = eval('(function () { var exports = {};' +
                      javascriptSource + '; return exports; })()');
    } catch (e) {
        log('Failed to load ' + from.get_uri() + ' : ' + e);
        throw e;
    }

    return module;
};

// file: GFile
let loadJavascriptFile = function(file) {
    let [, javascriptSource] = file.load_contents(null);

    let module = null;
    try {
        module = eval('(function () { var exports = {};' +
                          javascriptSource + '; return exports; })()');
    } catch (e) {
        log('Failed to load ' + file.get_uri() + ' : ' + e);
        throw e;
    }

    return module;
};

// vpath: string, doesn't include extension
let loadJavascript = function(vpath) {
    let path = Runtime.resolvePath(vpath);
    let file = Gio.File.new_for_uri(path + '.js');

    let module = loadJavascriptFile(file);

    return module;
};

// vpath: string, doesn't include extension
let loadCoffeescript = function(vpath) {
    let sourcePath = Runtime.resolvePath(vpath);
    let cachedPath = Runtime.resolveCachedPath(vpath);
    let sourceFile = Gio.File.new_for_uri(sourcePath + '.coffee');
    let cachedFile = Gio.File.new_for_uri(cachedPath + '.js');

    if (cachedFile.query_exists(null)) {
        let sourceFileInfo = sourceFile.query_info('time::modified',
                                                   Gio.FileQueryInfoFlags.NONE,
                                                   null);
        let cachedFileInfo = cachedFile.query_info('time::modified',
                                                   Gio.FileQueryInfoFlags.NONE,
                                                   null);
        if (sourceFileInfo.get_modification_time().tv_sec >
            cachedFileInfo.get_modification_time().tv_sec)
            return compileFile(cachedFile, sourceFile);
    } else
        return compileFile(cachedFile, sourceFile);

    return loadJavascriptFile(cachedFile);
};

// Tests:
//loadCoffeescript('library://components/noflo-gir/ComponentLoader');
