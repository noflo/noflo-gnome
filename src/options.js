let parseArguments = function(options, args) {
    let lookup = {};

    for (let i in options) {
        lookup[options[i].name] = options[i];
        if (options[i].shortName)
            lookup[options[i].shortName] = options[i];
    }

    let result = {
        options: {},
        arguments: [],
    };
    for (let i in args) {
        let match;
        if ((match = /--([\w-]+)(=(.*))?$/.exec(args[i])) == null &&
            (match = /-([\w-])(=(.*))?/.exec(args[i])) == null) {
            result.arguments.push(args[i]);
            continue;
        }

        let name = match[1];
        let value = match[3] != undefined ? match[3] : true;

        if (!lookup[name])
            throw new Error('Unkown option ' + args[i]);

        result.options[name] = value;
    }

    return result;
};

// Test
// const options = [
//     {
//         name: 'name',
//         shortName: 'n',
//         requireArgument: true,
//     },
//     {
//         name: 'test',
//         shortName: 't',
//         requireArgument: false,
//     },
// ];

// try {
//     let ret = parseArguments(options, ARGV);
//     for (let i in ret.options)
//         log(i + ' : ' + ret.options[i]);
// } catch (e) {
//     log(e.message);
// }
