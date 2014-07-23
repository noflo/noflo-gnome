const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const Utils = imports.utils;

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
            Utils.resolvePath('local://manifest.json'));
        _manifest = JSON.parse(content);
    } catch (e) {
        log('Cannot load application manifest: ' + e.message);
    }

    return _manifest;
}
