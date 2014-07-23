const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const ComponentLoader = imports.componentLoader;
const Options = imports.options;
const Path = imports.path;
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
let addRuntimeFile = function(srcPath, dstPath, dest) {
    Utils.copyFile(srcPath, dest + '/' + dstPath);
    return dstPath;
};

let addFile = function(path, subdir, dest) {
    Utils.copyFile(path, dest + '/' + subdir + '/' + path);
    return subdir + '/' + path;
};

let addFileContent = function(path, content, dest) {
    Utils.saveTextFileContent(dest + '/' + path, content);
    return path;
};

let addModule = function(loader, module, dest) {
    //log('add module ' + module.name);
    let files = [];
    // strip vpath scheme to get relative directory
    let dir = /[\w\d]+:\/\/(.*)/.exec(module.vpath)[1] + '/';

    // Add components
    for (let componentName in module.noflo.components) {
        let componentPath = module.noflo.components[componentName];
        files.push(addFileContent(dir + componentPath,
                                  loader.getComponentCode(module.normalizedName + '/' + componentName),
                                  dest));
    }

    // Add graphs
    for (let graphName in module.noflo.graphs) {
        let graphPath = module.noflo.graphs[graphName];
        files.push(addFileContent(dir + graphPath,
                                  loader.getComponentCode(module.normalizedName + '/' + graphName),
                                  dest));
    }

    // Loader
    if (module.noflo.loader) {
        files.push(addFileContent(dir + module.noflo.loader,
                                  Utils.loadTextFileContent(Utils.resolvePath(module.vpath + '/' + module.noflo.loader)),
                                  dest));
    }

    // index
    files.push(addFileContent(dir + 'component.json',
                              Utils.loadTextFileContent(Utils.resolvePath(module.vpath + '/component.json')),
                              dest));

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

    //
    currentDirectory = Gio.File.new_for_path(GLib.getenv('PWD'));

    // Load manifest
    let manifestPath = currentDirectory.get_path() + '/manifest.json';
    if (!GLib.file_test(manifestPath, GLib.FileTest.EXISTS))
        throw new Error('Cannot find repository manifest');

    // Parse manifest
    let manifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));

    // Create temporary directory
    let files = [];
    let tmpDir = GLib.dir_make_tmp('XXXXXX');

    // Add runtime files
    let runtimeDirectory = Gio.File.new_for_path(Path.RESOURCE_DIR + '/js');
    Utils.forEachInDirectory(runtimeDirectory, true, function(child) {
        if (child.query_file_type(Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                  null) != Gio.FileType.REGULAR)
            return;
        files.push(addRuntimeFile(child.get_path(),
                                  'runtime/' + runtimeDirectory.get_relative_path(child),
                                  tmpDir));
    });

    // Add application ui files
    for (let i in manifest.ui)
        files.push(addFile(manifest.ui[i].file,
                           'application',
                           tmpDir));

    // Add application DBus files
    for (let i in manifest.dbus)
        files.push(addFile(manifest.dbus[i].file,
                           'application',
                           tmpDir));

    // Add application components
    for (let componentName in manifest.noflo.components) {
        let componentPath = manifest.noflo.components[componentName];
        files.push(addFile(componentPath,
                           'application',
                           tmpDir));
    }

    // Add application graphs
    for (let graphName in manifest.noflo.graphs) {
        let graphPath = manifest.noflo.graphs[graphName];
        files.push(addFile(graphPath,
                           'application',
                           tmpDir));
    }

    // Add dependency modules
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

    // GResource index
    Utils.saveTextFileContent(tmpDir + '/app.xml',
                              generateIndex(files));

    // Generate resource file
    GLib.spawn_command_line_sync('glib-compile-resources' +
                                 ' --sourcedir ' + tmpDir +
                                 ' --target app.gresource' +
                                 ' ' + tmpDir + '/app.xml');
    log('Bundled ' + files.length + ' files');

    // TODO: remove packaging directory

    // Compress resource file
    let compressed = Gio.MemoryOutputStream.new_resizable()
    let output = new Gio.ConverterOutputStream({
        base_stream: compressed,
        converter: new Gio.ZlibCompressor({
            format: Gio.ZlibCompressorFormat.GZIP,
        }),
    });
    let resourceFile = Gio.File.new_for_path('app.gresource');
    output.splice(resourceFile.read(null),
                  Gio.OutputStreamSpliceFlags.CLOSE_SOURCE,
                  null);
    output.flush(null);
    output.close(null);

    resourceFile.delete(null);

    // Base64 content
    let base64 = GLib.base64_encode(compressed.steal_as_bytes().get_data());

    // Insert into bundle
    let template = Utils.loadTextFileContent(Path.RESOURCE_DIR +
                                             '/bundle/bundle.sh.in');
    template = template.replace('@@APP_DATA@@', base64);
    Utils.saveTextFileContent(manifest.name, template);

    // Set executable
    let executable = Gio.File.new_for_path(manifest.name);
    executable.set_attribute_uint32('unix::mode',
                                    parseInt('0755', 8),
                                    Gio.FileQueryInfoFlags.NONE, null);

    return 0;
};
