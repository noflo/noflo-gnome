const GLib = imports.gi.GLib;
const Path = imports.path;
const Utils = imports.utils;

let writeGraph = function(graph) {
    let graphPath = Path.CURRENT_DIR + '/graphs/' + graph.name + '.json';

    log('writing ' + graphPath);

    Utils.saveTextFileContent(graphPath,
                              JSON.stringify(graph.toJSON(), null, " "));
};
