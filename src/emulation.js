const GLib = imports.gi.GLib;

let inject = function() {
    let scope = window;
    scope.setTimeout = function(cb, time) {
        let timeout = {
            cleared: false,
            id: 0
        };

        timeout.id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
            cb();
            timeout.cleared = true;
            return false;
        }, null, null);
        return timeout;
    };
    scope.setInterval = function(cb, time) {
        let timeout = {
            cleared: false,
            id: GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
                cb();
                return true;
            }, null, null)
        };
        return timeout;
    };
    scope.clearTimeout = function(timeout) {
        if (timeout !== undefined &&
            timeout !== null &&
            timeout.id > 0 &&
            !timeout.cleared) {
            GLib.source_remove(timeout.id);
        }
    };
    scope.clearInterval = scope.clearTimeout;
};
