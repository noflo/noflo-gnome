const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const CodeLoader = imports.codeLoader;
const ComponentLoader = imports.componentLoader;
const Options = imports.options;
const Path = imports.path;
const Runtime = imports.runtime;
const Utils = imports.utils;

const CmdOptions = [
    {
        name: 'include-code',
        shortName: 'c',
        requireArgument: false,
        defaultValue: false,
        help: 'Include debug component code'
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
let outputUri = null;
let includeCode = false
let currentDirectory = null

//
let addRuntimeFile = function(srcPath, dstPath) {
    try {
        Utils.copyFile(srcPath, outputUri + '/' + dstPath);
    } catch (e) {
        log('Cannot add ' + srcPath);
        throw e;
    }
    return dstPath;
};

let addFile = function(path, subdir) {
    let uri = currentDirectory.get_uri() + '/';
    try {
        if (subdir) {
            Utils.copyFile(uri + path, outputUri + '/' + subdir + '/' + path);
            return subdir + '/' + path;
        } else {
            Utils.copyFile(uri + path, outputUri + '/' + path);
            return path;
        }
    } catch (e) {
        log('Cannot add ' + path);
        throw e;
    }
    return null;
};

let addFileContent = function(path, content) {
    try {
        Utils.saveTextFileContent(outputUri + '/' + path, content);
    } catch (e) {
        log('Cannot add ' + path);
        throw e;
    }
    return path;
};

let addModule = function(loader, module) {
    let files = [];
    // strip vpath scheme to get relative directory
    let dir = /[\w\d]+:\/\/(.*)/.exec(module.vpath)[1] + '/';

    // Add scripts
    for (let i in module.scripts) {
        let scriptPath = module.scripts[i];
        let coffeeTest = /(.*)\.coffee/.exec(scriptPath);
        let source = Utils.loadTextFileContent(
            Runtime.resolvePath(module.vpath + '/' + scriptPath));
        if (coffeeTest) {
            files.push(addFileContent(dir + scriptPath, ''));
            files.push(addFileContent('cache/library/' + dir + coffeeTest[1] + '.js',
                                      CodeLoader.compileCoffeeSource(source)));
        }

        if (includeCode || !coffeeTest)
            files.push(addFileContent(dir + scriptPath, source));
    }

    // JSON data
    for (let i in module.json) {
        let jsonPath = module.json[i];
        files.push(addFileContent(dir + jsonPath,
                                  Utils.loadTextFileContent(
                                      Runtime.resolvePath(
                                          module.vpath + '/' + jsonPath))));
    }

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

    includeCode = options.options.include_code;

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
    let manifestPath = currentDirectory.get_uri() + '/manifest.json';
    if (!Utils.isPathRegular(manifestPath))
        throw new Error('Cannot find repository manifest');

    // Create temporary directory
    let files = [];
    let outputDir = GLib.dir_make_tmp('XXXXXX');
    outputUri = 'file://' + outputDir;

    // Parse manifest
    let manifest = Utils.parseJSON(Utils.loadTextFileContent(manifestPath));

    files.push(addFile('manifest.json', 'application'));

    // Add runtime files
    let runtimeDirectory = Gio.File.new_for_path(Path.RESOURCE_DIR + '/js');
    Utils.forEachInDirectory(runtimeDirectory, true, function(child) {
        if (child.query_file_type(Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                  null) != Gio.FileType.REGULAR)
            return;
        files.push(addRuntimeFile(
            child.get_uri(),
            'runtime/' + runtimeDirectory.get_relative_path(child)));
    });

    // Add application ui files
    for (let i in manifest.ui)
        files.push(addFile(manifest.ui[i].file, 'application'));

    // Add application DBus files
    for (let i in manifest.dbus)
        files.push(addFile(manifest.dbus[i].file, 'application'));

    // Add application components
    for (let componentName in manifest.noflo.components) {
        let componentPath = manifest.noflo.components[componentName];

        let coffeeTest = /(.*)\.coffee/.exec(componentPath);
        if (coffeeTest) {
            files.push(addFileContent('application/' + componentPath,
                                      ''));
            files.push(addFileContent('application/.noflo/' + coffeeTest[1] + '.js',
                                      CodeLoader.compileCoffeeSource(
                                          Utils.loadTextFileContent(
                                              currentDirectory.get_uri() + '/' + componentPath))));
        }

        if (includeCode || !coffeeTest)
            files.push(addFile(componentPath, 'application'));
    }

    // Add application graphs
    for (let graphName in manifest.noflo.graphs) {
        let graphPath = manifest.noflo.graphs[graphName];
        files.push(addFile(graphPath, 'application'));
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
        files = files.concat(addModule(loader, module));
    }

    // Special case for introspected components
    if (manifest.libraries)
        files = files.concat(addModule(loader,
                                       loader.getModule('noflo-gir')));

    // GResource index
    Utils.saveTextFileContent(outputUri + '/app.xml',
                              generateIndex(files));

    // Generate resource file
    GLib.spawn_command_line_sync('glib-compile-resources' +
                                 ' --sourcedir ' + outputDir +
                                 ' --target app.gresource' +
                                 ' ' + outputDir + '/app.xml');
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
    let template = Utils.loadTextFileContent(
        Runtime.resolvePath('internal://bundle/bundle.sh.in'));
    template = template.replace('@@APP_DATA@@', base64);
    Utils.saveTextFileContent(Runtime.resolvePath('local://' + manifest.name),
                              template);

    // Set executable
    let executable = Gio.File.new_for_path(manifest.name);
    executable.set_attribute_uint32('unix::mode',
                                    parseInt('0755', 8),
                                    Gio.FileQueryInfoFlags.NONE, null);

    return 0;
};
