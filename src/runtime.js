const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;

let nextMainFunc = null;


let start = function() {
    Mainloop.run('noflo-gnome');
    if (nextMainFunc)
        nextMainFunc();
};

let replaceMainloop = function(func) {
    nextMainFunc = func;
    Mainloop.quit('noflo-gnome');
};
