const GLib = imports.gi.GLib;
const Options = imports.options;

const builderInit = imports.builderInit;
const builderEdit = imports.builderEdit;

/**/

let printProgram = function(msg) {
    print('noflo-gnome: ' + msg);
}

let printHelp = function() {
    for (let i in commands) {
        let command = commands[i];
        print('\t' + i + '\t' + command.help);
    }
};

/**/

let commands = {
    'init': {
        exec: builderInit.exec,
        help: 'Initialize a new application repository',
    },
    'edit': {
        exec: builderEdit.exec,
        help: 'Edit an application repository',
    },
    'bundle': {
        exec: function(args) {},
        help: 'Create a bundle of an application repository',
    },
    'help': {
        exec: function(args) {
            printProgram('');
            printHelp();
        },
        help: 'Print this screen',
    },
};

/**/

let execCommand = function(cmd, args) {
    let command = commands[cmd];
    if (command) {
        try {
            return command.exec(args);
        } catch (e) {
            printProgram(cmd + ' : ' + e.message);
        }
    } else {
        printProgram('Unknown command ' + cmd);
        printHelp();
    }
    return -1;
};

/**/

let start = function() {
    if (ARGV[0])
        return execCommand(ARGV[0], ARGV.slice(1));

    printProgram('');
    printHelp();

    return 0;
}
