const GLib = imports.gi.GLib;
const Soup = imports.gi.Soup;
const Options = imports.options;
const Utils = imports.utils;

const CmdOptions = [
];

//
let exec = function(args) {
    let options = Options.parseArguments(CmdOptions, args);

    let manifest;
    try {
        manifest = Utils.parseJSON(
            Utils.loadTextFileContent(GLib.getenv('PWD') + '/manifest.json'));
        log('loaded manifest : ' + manifest.name);
    } catch (e) {
    }

    let runtime = {
        label: 'NoFlo Gnome',
        id: '516416d5-9d62-41a1-a901-7ac469455c03',
        protocol: 'websocket',
        address: 'ws://localhost:5555',
        type: 'noflo-gnome',
    };
    let project = {
        id: manifest.name,
        name: manifest.name,
        components: [],
        graphs: [],
        main: manifest.noflo.main,
        type: 'noflo-gnome',
    };

    let uri = 'http://localhost:1080/live.html#';
    uri += '?runtime=' + Soup.uri_encode(GLib.base64_encode(JSON.stringify(runtime)),
                                         null);
    uri += '&project=' + Soup.uri_encode(GLib.base64_encode(JSON.stringify(project)),
                                         null);

    print('Open: ' + uri);

    return 0;
};
