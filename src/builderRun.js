const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Soup = imports.gi.Soup;
const ComponentLoader = imports.componentLoader;
const NoFlo = imports.noflo;
const Options = imports.options;
const Runtime = imports.runtime;
const Utils = imports.utils;
const WebProtoServer = imports.websocketServer;


const CmdOptions = [
    {
        name: 'no-autosave',
        shortName: 'n',
        requireArgument: false,
        defaultValue: false,
        help: 'Disable autosaving mode when debugging',
    },
    {
        name: 'debug',
        shortName: 'd',
        requireArgument: false,
        defaultValue: false,
        help: 'Launch the application in debug mode',
    },
    {
        name: 'port',
        shortName: 'p',
        requireArgument: true,
        defaultValue: 5555,
        help: 'Specify a port to etablish the WebSocket '
            + 'connection with the UI',
    },
    {
        name: 'ui',
        shortName: 'u',
        requireArgument: false,
        defaultValue: false,
        help: 'Start the UI automatically',
    },
    {
        name: 'ui-url',
        shortName: 'y',
        requireArgument: true,
        defaultValue: 'http://app.flowhub.io',
        help: 'Use a custom version of the UI at the given url',
    },
    {
        name: 'help',
        shortName: 'h',
        requireArgument: false,
        defaultValue: false,
        help: 'Print this screen',
    },
];

let generateBrowserUrl = function(base_url, port, manifest) {
    let runtime = {
        label: 'NoFlo Gnome',
        id: '516416d5-9d62-41a1-a901-7ac469455c03',
        protocol: 'websocket',
        address: 'ws://localhost:' + port,
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

    let url = base_url + '/#runtime/endpoint'
    url += '?protocol=websocket'
    url += '&address=' + Soup.uri_encode('ws://localhost:' + port, null)

    print('Open: ' + url);
    return url;
};

//
let exec = function(args) {
    let options = Options.parseArguments(CmdOptions, args);

    if (options.options.help) {
        Options.printHelp('noflo-gnome run', CmdOptions);
        return -1;
    }

    let manifest;
    manifest = Utils.parseJSON(
        Utils.loadTextFileContent(
            Runtime.resolvePath('local://manifest.json')));

    Runtime.setArguments(options.arguments);

    if (options.options.debug) {
        if (options.options.ui) {
            // Start webbrowser with address
            Gio.AppInfo.launch_default_for_uri(
                generateBrowserUrl(options.options['ui-url'],
                                   options.options.port,
                                   manifest),
                null);
        }
        let server = new WebProtoServer.WebProtoServer({
            port: options.options.port,
            autosave: !options.options['no-autosave']
        });
        server.start();
        Runtime.run();
    } else {
        // Start runtime, no debug connection
        let runtime = new NoFlo.RuntimeBase({ baseDir: '/noflo-runtime-base',
                                              type: 'noflo-nodejs', });
        let loader = new ComponentLoader.ComponentLoader({
            baseDir: '/noflo-runtime-base',
            paths: [ 'system://components',
                     'library://components',
                     'local://components', ],
        });
        runtime.component.loaders = {
            '/noflo-runtime-base': loader,
        };
        loader.install(runtime);
        Runtime.run();
    }

    return 0;
};
