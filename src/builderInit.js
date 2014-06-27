const GLib = imports.gi.GLib;
const Options = imports.options;
const Utils = imports.utils;

const CmdOptions = [
    {
        name: 'version',
        shortName: 'v',
        requireArgument: true,
        defaultValue: '0.0.1',
    },
    {
        name: 'name',
        shortName: 'n',
        requireArgument: true,
        defaultValue: 'MyApplication',
    },
];

//
let exec = function(args) {
    let options = Options.parseArguments(CmdOptions, args);

    let manifest = {
        name: options.options['name'],
        version: options.options['version'],
        ui: [],
        components: [],
    };

    let manifestPath = GLib.getenv('PWD') + '/manifest.json';

    try {
        let oldManifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));
        Utils.mergeProps(manifest, oldManifest);
    } catch (e) {
    }

    Utils.saveTextFileContent(manifestPath, JSON.stringify(manifest, null, "  "));

    return 0;
};
