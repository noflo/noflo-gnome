const Lang = imports.lang;
const Mainloop = imports.mainloop;
const GLib = imports.gi.GLib;
const Soup = imports.gi.Soup;
const NoFlo = imports.noflo;
const Options = imports.options;
const Runtime = imports.runtime;
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

/**/

let _session = null;
let getSession = function() {
    if (_session == null)
        _session = new Soup.Session();
    return _session;
};

let _queue = 0;

let download = function(uri, callback) {
    let msg = Soup.Message.new('GET', uri);

    _queue++;

    getSession().queue_message(msg, Lang.bind(this, function(session, message) {
        callback(message);

        _queue--;
        if (_queue <= 0)
            Mainloop.quit('noflo-gnome-install');
    }));
};

/**/

let generateUrl = function(repo, file) {
    return 'https://raw.githubusercontent.com/' + repo + '/master/' + file;
};

let downloadedFile = function(repo, file, msg) {
    if (msg.status_code != Soup.KnownStatusCode.OK) {
        log("Couldn't download file " + file +
            ' from  repository : ' + repo +
            ' : ' + msg.reason_phrase);
        Mainloop.quit('noflo-gnome-install');
        return;
    }

    let flattenRepo = repo.replace('/', '-');
    let path = Runtime.resolvePath('library://components/' + flattenRepo + '/' + file);
    Utils.saveTextFileContent(path, msg.response_body.data);
};

let downloadedDescr = function(repo, msg) {
    if (msg.status_code != Soup.KnownStatusCode.OK) {
        log("Couldn't download informations from repository " + repo +
            ' : ' + msg.reason_phrase);
        Mainloop.quit('noflo-gnome-install');
        return;
    }

    let pkgstr = msg.response_body.data;
    try {
        let pkg = JSON.parse(pkgstr);
        print('Downloading : ' + repo);
        for (let i in pkg.scripts) {
            let file = pkg.scripts[i];
            let url = generateUrl(repo, file);
            download(url, function(msg) { downloadedFile(repo, file, msg); });
        }
        for (let i in pkg.json) {
            let file = pkg.json[i];
            let url = generateUrl(repo, file);
            download(url, function(msg) { downloadedFile(repo, file, msg); });
        }
    } catch (error) {
        log("Couldn't download repository : " + repo);
        Mainloop.quit('noflo-gnome-install');
    }
};

let downloadRepo = function(repo) {
    let url = generateUrl(repo, 'component.json');
    download(url, function(msg) { downloadedDescr(repo, msg); });
};

//
let exec = function(args) {
    let options = Options.parseArguments(CmdOptions, args);

    if (options.options.help) {
        Options.printHelp('noflo-gnome install', CmdOptions);
        return 0;
    }

    for (let i in options.arguments) {
        let repo = options.arguments[i];
        downloadRepo(repo);
    }

    Mainloop.run('noflo-gnome-install');

    return 0;
};
