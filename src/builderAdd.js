const GLib = imports.gi.GLib;
const Options = imports.options;
const Utils = imports.utils;

const CmdOptions = [
    {
        name: 'component',
        shortName: 'c',
        requireArgument: true,
        defaultValue: [],
        allowMultiple: true,
        help: 'Add a component to the manifest'
    },
    {
        name: 'dbus',
        shortName: 'd',
        requireArgument: true,
        defaultValue: [],
        allowMultiple: true,
        help: 'Add a DBus interface description file to the manifest'
    },
    {
        name: 'ui',
        shortName: 'u',
        requireArgument: true,
        defaultValue: [],
        allowMultiple: true,
        help: 'Add a UI file to the manifest'
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
        Options.printHelp('noflo-gnome add', CmdOptions);
        return 0;
    }

    // Load content
    let manifestPath = GLib.getenv('PWD') + '/manifest.json';
    if (!GLib.file_test(manifestPath, GLib.FileTest.EXISTS))
        throw new Error('Cannot find repository manifest');

    // Parse content
    let manifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));

    // Add components
    for (let i in options.options.component) {
        if (!manifest.noflo.components)
            manifest.noflo.components = {};
        let path = options.options.component[i];
        manifest.noflo.components[Utils.getFileName(path)] = path;
    }

    // Add ui files
    for (let i in options.options.ui) {
        if (!manifest.ui)
            manifest.ui = [];
        manifest.ui.push({
            file: options.options.ui[i],
            additionals: [],
        });
    }

    // Add DBus files
    for (let i in options.options.dbus) {
        if (!manifest.dbus)
            manifest.dbus = [];
        manifest.dbus.push({
            file: options.options.dbus[i],
        });
    }

    // Save the whole thing
    Utils.saveTextFileContent(manifestPath, JSON.stringify(manifest, null, "  "));

    return 0;
};