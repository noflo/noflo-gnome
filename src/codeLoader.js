const Gio = imports.gi.Gio;
const Utils = imports.utils;

const CoffeeScript = imports.libs.coffeescript.CoffeeScript;

// from: GFile
// to: GFile
let compileFile = function(to, from) {
    let [, coffeeSource] = from.load_contents(null);
    let javascriptSource = CoffeeScript.compile('' + coffeeSource,
                                                { bare: true });
    let module = eval('(function () { var exports = {};' +
                      javascriptSource + '; return exports; })()');

    // Compilation cache
    log('writing ' + to.get_path());
    try {
        to.get_parent().make_directory_with_parents(null);
    } catch (e) {
    }
    to.replace_contents(javascriptSource,
                        null,
                        false,
                        Gio.FileCreateFlags.NONE, null,
                        null);

    return module;
};

// file: GFile
let loadJavascriptFile = function(file) {
    let [, javascriptSource] = file.load_contents(null);

    let module = eval('(function () { var exports = {};' +
                      javascriptSource + '; return exports; })()');

    return module;
};

// vpath: string, doesn't include extension
let loadJavascript = function(vpath) {
    let path = Utils.resolvePath(vpath);
    let file = Gio.File.new_for_path(path + '.js');
    let [, javascriptSource] = file.load_contents(null);

    let module = eval('(function () { var exports = {};' +
                      javascriptSource + '; return exports; })()');

    return module;
};

// vpath: string, doesn't include extension
let loadCoffeescript = function(vpath) {
    let sourcePath = Utils.resolvePath(vpath);
    let cachedPath = Utils.resolveCachedPath(vpath);
    let sourceFile = Gio.File.new_for_path(sourcePath + '.coffee');
    let cachedFile = Gio.File.new_for_path(cachedPath + '.js');

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
