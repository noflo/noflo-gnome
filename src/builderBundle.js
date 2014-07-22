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
let addFile = function(path, directory) {
    Utils.copyFile(path, directory + '/' + path);
    return path;
};

let addFileContent = function(path, content, directory) {
    Utils.saveTextFileContent(directory + '/' + path, content);
    return path;
};

let addModule = function(loader, module, directory) {
    let files = [];
    // strip vpath scheme to get relative directory
    let dir = /[\w\d]+:\/\/(.*)/.exec(module.vpath)[1] + '/';

    // Add components
    for (let componentName in module.noflo.components) {
        let componentPath = module.noflo.components[componentName];
        files.push(addFileContent(dir + componentPath,
                                  loader.getComponentCode(module.normalizedName + '/' + componentName),
                                  directory));
    }

    // Add graphs
    for (let graphName in module.noflo.graphs) {
        let graphPath = module.noflo.graphs[graphName];
        files.push(addFileContent(dir + graphPath,
                                  loader.getComponentCode(module.normalizedName + '/' + graphName),
                                  directory));
    }

    // Loader
    if (module.noflo.loader) {
        files.push(addFileContent(dir + module.noflo.loader,
                                  Utils.loadTextFileContent(Utils.resolvePath(module.vpath + '/' + module.noflo.loader)),
                                  directory));
    }

    // index
    files.push(addFileContent(dir + 'component.json',
                              Utils.loadTextFileContent(Utils.resolvePath(module.vpath + '/component.json')),
                              directory));

    return files;
};

let generateIndex = function(files) {
    let data =
        '<?xml version="1.0" encoding="UTF-8"?>\n' +
        '<gresources>\n' +
        ' <gresource prefix="/org/gnome/noflo-gnome">\n';

    for (let i in files)
        data += '  <file>' + files[i] + '</file>\n';

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

    // Load manifest
    let manifestPath = GLib.getenv('PWD') + '/manifest.json';
    if (!GLib.file_test(manifestPath, GLib.FileTest.EXISTS))
        throw new Error('Cannot find repository manifest');

    // Parse manifest
    let manifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));

    // Create temporary directory
    let files = [];
    let tmpDir = GLib.dir_make_tmp('XXXXXX');
    log('output dir : ' + tmpDir);

    // Add ui files
    for (let i in manifest.ui)
        files.push(addFile(manifest.ui[i].file, tmpDir));

    // Add DBus files
    for (let i in manifest.dbus)
        files.push(addFile(manifest.dbus[i].file, tmpDir));

    // Add main module
    let components = {};
    let modules = {};

    let mainGraph = loader.mainGraph.getDefinition();
    for (let i in mainGraph.processes) {
        let cmp = mainGraph.processes[i].component;
        if (components[cmp])
            continue;

        components[cmp] = true;

        let module = loader.getComponentModule(cmp);
        if (!module ||
            modules[module.name] || // drop already loaded modules
            module.name == loader.applicationName) // drop app components
            continue;

        modules[module.name] = module;
        files = files.concat(addModule(loader, module, tmpDir));
    }

    // TODO: add app components

    // GResource index
    log('number of files: ' + files.length);
    Utils.saveTextFileContent(tmpDir + '/app.xml',
                              generateIndex(files));

    // Generate resource file
    log('glib-compile-resources' +
                                 ' --sourcedir ' + tmpDir +
                                 ' --target app.gresource' +
                                 ' ' + tmpDir + '/app.xml');
    GLib.spawn_command_line_sync('glib-compile-resources' +
                                 ' --sourcedir ' + tmpDir +
                                 ' --target app.gresource' +
                                 ' ' + tmpDir + '/app.xml');

    return 0;
};
