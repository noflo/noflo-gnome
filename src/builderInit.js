const GLib = imports.gi.GLib;
const NoFlo = imports.noflo;
const Options = imports.options;
const Runtime = imports.runtime;
const Utils = imports.utils;

const CmdOptions = [
    {
        name: 'version',
        shortName: 'v',
        requireArgument: true,
        defaultValue: '0.0.1',
        help: 'Version for application repository'
    },
    {
        name: 'name',
        shortName: 'n',
        requireArgument: true,
        defaultValue: 'MyApplication',
        help: 'Name for application repository'
    },
    {
        name: 'help',
        shortName: 'h',
        requireArgument: false,
        defaultValue: false,
        help: 'Print this screen'
    },
];

//
let exec = function(args) {
    let options = Options.parseArguments(CmdOptions, args);

    if (options.options.help) {
        Options.printHelp('noflo-gnome init', CmdOptions);
        return 0;
    }

    let manifestPath = Runtime.resolvePath('local://manifest.json');
    if (Utils.isPathRegular(manifestPath))
        throw new Error('Cannot initialize repository, already initialized');

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
    let mainGraphPath = Runtime.resolvePath('local://' + manifest.noflo.graphs.Main);

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
