const GLib = imports.gi.GLib;
const NoFlo = imports.noflo;
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
    let manifestPath = GLib.getenv('PWD') + '/manifest.json';
    if (GLib.file_test(manifestPath, GLib.FileTest.EXISTS))
        throw new Error('Cannot initialize repository, already initialized');

    let options = Options.parseArguments(CmdOptions, args);

    let manifest = {
        name: options.options['name'],
        version: options.options['version'],
        ui: [],
        noflo: {
            components: {},
            graphs: {
                'Main': 'graphs/Main.json'
            },
            main: 'Main'
        },
    };
    let mainGraphPath = GLib.getenv('PWD') + '/' + manifest.noflo.graphs.Main;

    try {
        let oldManifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));
        Utils.mergeProps(manifest, oldManifest);
    } catch (e) {
    }

    Utils.saveTextFileContent(manifestPath, JSON.stringify(manifest, null, "  "));
    Utils.saveTextFileContent(mainGraphPath,
                              JSON.stringify((new NoFlo.NoFlo.Graph(manifest.noflo.main)).toJSON(),
                                             null, "  "));

    return 0;
};
