const Gio = imports.gi.Gio;
const Path = imports.path;

let copy = function(obj2) {
    let ret = {}
    for (let i in obj2) {
	ret[i] = obj2[i];
    }
    return ret;
};

let copyList = function(list) {
    let ret = []
    for (let i in list)
	ret.push(list[i]);
    return ret;
};

let mergeProps = function(obj1, obj2) {
    if (obj1 === undefined || obj1 === null)
        obj1 = {};
    for (let i in obj2) {
	obj1[i] = obj2[i];
    }
    return obj1;
};

let parseProps = function(obj1, obj2) {
    let ret = {};
    for (let i in obj2) {
        if (obj1[i] == undefined) {
            ret[i] = obj2[i];
        } else {
            ret[i] = obj1[i];
            delete obj1[i];
        }
    }
    return ret;
};

let boxToString = function(box) {
    return '' + box.x1 + 'x' + box.y1 + ' -> ' + box.x2 + 'x' + box.y2;
};

let allocationBoxToString = function(box) {
    return '' + box.width + 'x' + box.height + ' @ ' + box.x + 'x' + box.y;
};

let levelToSpaces = function(level) {
    let ret = ''
    for (let i = 0; i < level; i++)
        ret += '   ';
    return ret;
};

let forEachInDirectory = function(directory, callback) {
    let enumerator = directory.enumerate_children('*',
                                                  Gio.FileQueryInfoFlags.NONE,
                                                  null);
    let fileInfo;
    while ((fileInfo = enumerator.next_file(null)) != null) {
        let child = enumerator.get_child(fileInfo);
        callback(child);
    }
    enumerator.close(null);
};

let buildPath = function(parent, child) {
    return parent + '/' + child;
};

let resolvePath = function(virtualPath) {
    let ret;
    if ((ret = /^library:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Path.RESOURCE_DIR + '/' + ret[1];
    else if ((ret = /^local:\/\/(.*)/.exec(virtualPath)) != null)
        ret = ret[1];
    else
        ret = virtualPath

    //log('path : ' + virtualPath + ' ->  ' + ret);

    return ret;
};

let resolveCachedPath = function(virtualPath) {
    let ret;
    if ((ret = /^library:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Path.CACHE_DIR + '/library/' + ret[1];
    else if ((ret = /^local:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Path.CACHE_DIR + '/local/' + ret[1]; // TODO: should be local
    else
        ret = virtualPath

    //log('cached path : ' + virtualPath + ' ->  ' + ret);

    return ret;
};

let guessLanguageFromFilename = function(filename) {
    if (/.*\.coffee$/.test(filename))
        return 'coffeescript';
    return 'javascript';
}
