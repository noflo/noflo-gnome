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
        label: 'NoFlo Gnome - ' + (manifest != null ? manifest.name : ''),
        id: '516416d5-9d62-41a1-a901-7ac469455c03',
        protocol: 'websocket',
        address: 'ws://localhost:5555',
        type: 'noflo-gnome',
    };

    let uri = 'http://localhost:1080/#';
    uri += '?runtime=' + GLib.base64_encode(JSON.stringify(runtime));

    print('Open: ' + uri);

    return 0;
};
