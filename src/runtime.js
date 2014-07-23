const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const Path = imports.path;
const Utils = imports.utils;


/**/

let _resourceDir = function() {
    if (_bundled)
        return 'resource:///org/gnome/noflo-gnome/';
    else
        return Path.RESOURCE_DIR;
};

let _currentDir = function() {
    if (_bundled)
        return 'resource:///org/gnome/noflo-gnome/application';
    else
        return Path.CURRENT_DIR;
};

let resolvePath = function(virtualPath) {
    let ret;
    if ((ret = /^library:\/\/(.*)/.exec(virtualPath)) != null)
        ret = _resourceDir() + '/' + ret[1];
    else if ((ret = /^local:\/\/(.*)/.exec(virtualPath)) != null)
        ret = _currentDir() + '/' + ret[1];
    else
        ret = virtualPath
    //log('path : ' + virtualPath + ' ->  ' + ret);

    return ret;
};

let resolveCachedPath = function(virtualPath) {
    let ret;
    if ((ret = /^library:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Path.CACHE_DIR + '/library/' + ret[1];
    else if ((ret = /^local:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Path.CACHE_DIR + '/local/' + ret[1]; // TODO: should be local
    else
        ret = virtualPath
    //log('cached path : ' + virtualPath + ' ->  ' + ret);

    return ret;
};


/**/

let nextMainFunc = null;
let run = function() {
    Mainloop.run('noflo-gnome');
    while (nextMainFunc != null) {
        let mainFunc = nextMainFunc;
        nextMainFunc = null;
        mainFunc();
    }
};

let replaceMainloop = function(func) {
    nextMainFunc = func;
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
