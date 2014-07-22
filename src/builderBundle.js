const GLib = imports.gi.GLib;
const ComponentLoader = imports.componentLoader;
const Options = imports.options;
const Utils = imports.utils;

const CmdOptions = [
    {
        name: 'help',
        shortName: 'h',
        requireArgument: false,
        defaultValue: false,
        help: 'Print this screen'
    },
];

//
let addFile = function(path, tmpDir) {
    Utils.copyFile(path, tmpDir + '/' + path);
    return path;
};

let addFileContent = function(path, content, tmpDir) {
    Utils.saveTextFileContent(tmpDir + '/' + path, content);
    return path;
};

let addModule = function(path, index, tmpDir) {
    let files = [];

    let manifestPath = path + '/' + index;
    if (!GLib.file_test(manifestPath, GLib.FileTest.EXISTS))
        throw new Error('Cannot find repository manifest');

    // Parse manifest
    let manifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));

    // Add components
    for (let i in manifest.noflo.components) {


        files.push(addFile(path + '/' + manifest.noflo.components[i], tmpDir));
    }

    // Add graphs
    for (let i in manifest.noflo.graphs)
        files.push(addFile(path + '/' + manifest.noflo.graphs[i], tmpDir));

    // index
    files.push(addFileContent(path + '/' + index, JSON.stringify(manifest), tmpDir));

    return files;
};

let generateIndex = function(files) {
    let data =
        '<?xml version="1.0" encoding="UTF-8"?>\n' +
        '<gresources>\n' +
        ' <gresource prefix="/org/gnome/noflo-gnome">\n';

    for (let i in files)
        data += '<file>' + files[i] + '</file>\n';

    data +=
        ' </gresource>\n' +
        '</gresources>';

    return data;
};

//
let exec = function(args) {
    let options = Options.parseArguments(CmdOptions, args);

    if (options.options.help) {
        Options.printHelp('noflo-gnome bundle', CmdOptions);
        return 0;
    }

    // Get library loader
    let loader = new ComponentLoader.ComponentLoader({
        baseDir: '/noflo-runtime-base',
        paths: [ 'library://components',
                 'local://components', ],
    });
    loader.loadModules();

    // Load content
    let manifestPath = GLib.getenv('PWD') + '/manifest.json';
    if (!GLib.file_test(manifestPath, GLib.FileTest.EXISTS))
        throw new Error('Cannot find repository manifest');

    // Parse manifest
    let manifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));

    let files = [];
    let tmpDir = GLib.dir_make_tmp('XXXXXX');

    // Add ui files
    for (let i in manifest.ui)
        files.push(addFile(manifest.ui[i].file, tmpDir));

    // Add DBus files
    for (let i in manifest.dbus)
        files.push(addFile(manifest.dbus[i].file, tmpDir));

    // Add main module
    //files = files.concat(addModule(GLib.getenv('PWD'), 'manifest.json', tmpDir));
    let mainGraph = loader.mainGraph.getCode();
    log('Got : ' + mainGraph.name + ' - ' + mainGraph.language);
    let components = {};
    log(mainGraph.processes);
    for (let i in mainGraph.processes) {
        let cmp = mainGraph.processes[i].component;
        if (components[cmp])
            continue;

        loader.getSource(cmp, function(error, compDesc) {
            if (error)
                throw error;
            components[cmp] = compDesc;
        });
        log(' ' + cmp);
    }

    // GResource index
    Utils.saveTextFileContent(tmpDir + '/app.xml',
                              generateIndex(files));

    // Generate resource file
    GLib.spawn_command_line_sync('glib-compile-resources' +
                                 ' --sourcedir ' + tmpDir +
                                 ' --target app.gresource' +
                                 ' ' + tmpDir + '/app.xml');

    return 0;
};
