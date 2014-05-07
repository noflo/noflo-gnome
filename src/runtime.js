const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;

let nextMainFunc = null;


let start = function() {
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
