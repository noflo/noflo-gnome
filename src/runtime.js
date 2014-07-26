const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const Path = imports.path;
const Utils = imports.utils;

/**/

let _bundled;
let setBundled = function(value) {
    _bundled = value;
};

/**/

let _resourceDir = function() {
    if (_bundled)
        return 'resource:///org/gnome/noflo-gnome/';
    else
        return 'file://' + Path.RESOURCE_DIR;
};

let _currentDir = function() {
    if (_bundled)
        return 'resource:///org/gnome/noflo-gnome/application';
    else
        return 'file://' + Path.CURRENT_DIR;
};

let _cacheDir = function() {
    if (_bundled)
        return 'resource:///org/gnome/noflo-gnome/cache';
    else
        return 'file://' + Path.CACHE_DIR;
};

let _internalDir = function() {
    if (_bundled)
        return 'resource:///org/gnome/noflo-gnome/runtime';
    else
        return 'file://' + Path.RESOURCE_DIR
};

let resolvePath = function(virtualPath) {
    let ret;
    if ((ret = /^library:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Utils.buildPath(_resourceDir(), ret[1]);
    else if ((ret = /^local:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Utils.buildPath(_currentDir(), ret[1]);
    else if ((ret = /^internal:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Utils.buildPath(_internalDir(), ret[1]);
    else
        ret = virtualPath
    //log('path : ' + virtualPath + ' ->  ' + ret);

    return ret;
};

let resolveCachedPath = function(virtualPath) {
    let ret;
    if ((ret = /^library:\/\/(.*)/.exec(virtualPath)) != null)
        ret = _cacheDir() + '/library/' + ret[1];
    else if ((ret = /^local:\/\/(.*)/.exec(virtualPath)) != null)
        ret = _cacheDir() + '/local/' + ret[1]; // TODO: should be local
    else
        ret = virtualPath
    //log('cached path : ' + virtualPath + ' ->  ' + ret);

    return ret;
};


/**/

let nextMainFunc = [];
let inRuntimeMainloop = true;
let run = function() {
    Mainloop.run('noflo-gnome');
    inRuntimeMainloop = false;
    while (nextMainFunc.length > 0) {
        let mainFunc = nextMainFunc.shift();
        mainFunc();
    }
};

let replaceMainloop = function(func) {
    nextMainFunc.push(func);
    if (inRuntimeMainloop)
        Mainloop.quit('noflo-gnome');
};

/**/

let _arguments = null;
let setArguments = function(args) {
    _arguments = args;
};

let getArguments = function() {
    return _arguments;
};

/**/

let _manifest = null;
let getApplicationManifest = function() {
    if (_manifest)
        return _manifest;

    try {
        let content = Utils.loadTextFileContent(
            resolvePath('local://manifest.json'));
        _manifest = JSON.parse(content);
    } catch (e) {
        log('Cannot load application manifest: ' + e.message);
    }

    return _manifest;
}
