let parseArguments = function(options, args) {
    let lookup = {};
    let result = {
        options: {},
        arguments: [],
    };

    for (let i in options) {
        let option = options[i];
        lookup[option.name] = options[i];
        if (option.shortName)
            lookup[option.shortName] = options[i];
        if (option.defaultValue !== undefined)
            result.options[option.name] = option.defaultValue;
    }

    let isValue = false, lastOption = null;
    for (let i in args) {
        if (lastOption) {
            result.options[lastOption.name] = args[i];
            lastOption = null;
            continue;
        }

        let match;
        //log("looking at : '" + args[i] + "'");
        if ((match = /^--([\w-]+)(=(.*))?$/.exec(args[i])) == null &&
            (match = /^-([\w-])(=(.*))?$/.exec(args[i])) == null) {
            if (args[i][0] == '-')
                throw new Error('Unknown option ' + args[i]);
            result.arguments.push(args[i]);
            continue;
        }

        let name = match[1];
        let value = match[3];
        //log("match: '" + name + "' value: '" + match[3] + "'");
        let option = lookup[name];
        if (!option)
            throw new Error('Unkown option ' + name);
        if (!option.requireArgument) {
            if (value != undefined)
                throw new Error('Invalid value for option ' + name + ' : ' + value);
            else
                result.options[option.name] = true;
        } else {
            if (value != undefined)
                result.options[option.name] = value;
            else
                lastOption = option;
        }
    }

    return result;
};

let printHelp = function(header, options) {
    print(header + ':');
    for (let i in options) {
        let opt = options[i];
        let line = '\t--' + opt.name;

        if (opt.shortName)
            line += ', -' + opt.shortName;
        if (opt.requireArgument)
            line += '=VALUE';
        line += '\t' + opt.help
        print(line);
    }
};

// Test
const TEST = false;

const options = [
    {
        name: 'name',
        shortName: 'n',
        requireArgument: true,
        defaultValue: 'noname',
    },
    {
        name: 'test',
        shortName: 't',
        requireArgument: false,
        defaultValue: false,
    },
];

if (TEST) {
    try {
        let ret = parseArguments(options, ARGV);
        for (let i in ret.options)
            log(i + ' : ' + ret.options[i]);
    } catch (e) {
        log('Error: ' + e.message);
    }
}
