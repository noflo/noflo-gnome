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

let manifest = {};
let getApplicationManifest = function() {
    let content = Utils.loadTextFileContent(
        Utils.resolvePath('local://manifest.json'));

    try {
        manifest = JSON.parse(content);
    } catch (e) {
        log('Cannot load application manifest: ' + e.message);
    }

    return manifest;
}
