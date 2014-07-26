const GLib = imports.gi.GLib;
const Path = imports.path;
const Runtime = imports.runtime;
const Utils = imports.utils;

let writeGraph = function(graph) {
    let graphPath = Runtime.resolvePath('local://graphs/' + graph.name + '.json');

    log('writing ' + graphPath);

    Utils.saveTextFileContent(graphPath,
                              JSON.stringify(graph.toJSON(), null, " "));
};
