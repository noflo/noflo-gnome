const GLib = imports.gi.GLib;

let inject = function() {
    let scope = window;
    scope.setTimeout = function(cb, time) {
        return GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
            cb();
            return false;
        }, null, null);
    };
    scope.setInterval = function(cb, time) {
        return GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
            cb();
            return true;
        }, null, null);
    };
    scope.clearTimeout = function(id) {
        if (id > 0)
            GLib.source_remove(id);
    };
    scope.clearInterval = scope.clearTimeout;
};
