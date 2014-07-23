const GLib = imports.gi.GLib;
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

let forEachInDirectory = function(directory, recurse, callback) {
    let enumerator = directory.enumerate_children('*',
                                                  Gio.FileQueryInfoFlags.NONE,
                                                  null);
    let fileInfo;
    while ((fileInfo = enumerator.next_file(null)) != null) {
        let child = enumerator.get_child(fileInfo);
        if (recurse &&
            child.query_file_type(Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                  null) == Gio.FileType.DIRECTORY) {
            callback(child);
            forEachInDirectory(child, recurse, callback);
        } else
            callback(child);
    }
    enumerator.close(null);
};

let getFileName = function(path) {
    let match = /.*\/([^\/]+)\.[^\/\.]*/.exec(path)
    if (match)
        return match[1];
    match = /([^\/]+)\.[^\/\.]*/.exec(path)
    if (match)
        return match[1]
    return null;
}

let buildPath = function(parent, child) {
    return parent + '/' + child;
};

let resolvePath = function(virtualPath) {
    let ret;
    if ((ret = /^library:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Path.RESOURCE_DIR + '/' + ret[1];
    else if ((ret = /^local:\/\/(.*)/.exec(virtualPath)) != null)
        ret = Path.CURRENT_DIR + '/' + ret[1];
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

let loadTextFileContent = function(path) {
    let file = Gio.File.new_for_path(path);
    let [, content] = file.load_contents(null);
    return '' + content;
};

let saveTextFileContent = function(path, content) {
    let file = Gio.File.new_for_path(path);
    let parent = file.get_parent();

    if (!parent.query_exists(null))
        parent.make_directory_with_parents(null);

    file.replace_contents(content,
                          null,
                          false,
                          Gio.FileCreateFlags.NONE, null,
                          null);
};

let copyFile = function(from, to) {
    let fromFile = Gio.File.new_for_path(from);
    let toFile = Gio.File.new_for_path(to);
    let parent = toFile.get_parent();

    if (!parent.query_exists(null))
        parent.make_directory_with_parents(null);

    fromFile.copy(toFile, Gio.FileCopyFlags.OVERWRITE, null, null);
};

let parseJSON = function(data) {
    try {
        return JSON.parse(data);
    } catch (e) {
    }
    return null;
};

let guessLanguageFromFilename = function(filename) {
    if (/.*\.coffee$/.test(filename))
        return 'coffeescript';
    return 'javascript';
}

// Copied from GJS with a slight modification :
// https://bugzilla.gnome.org/show_bug.cgi?id=733389
let unpackVariant = function(variant, deep) {
    switch (String.fromCharCode(variant.classify())) {
    case 'b':
	return variant.get_boolean();
    case 'y':
	return variant.get_byte();
    case 'n':
	return variant.get_int16();
    case 'q':
	return variant.get_uint16();
    case 'i':
	return variant.get_int32();
    case 'u':
	return variant.get_uint32();
    case 'x':
	return variant.get_int64();
    case 't':
	return variant.get_uint64();
    case 'h':
	return variant.get_handle();
    case 'd':
	return variant.get_double();
    case 'o':
    case 'g':
    case 's':
	// g_variant_get_string has length as out argument
	return variant.get_string()[0];
    case 'v':
        if (deep)
            return unpackVariant(variant.get_variant(), deep);
        else
	    return variant.get_variant();
    case 'm':
	let val = variant.get_maybe();
	if (deep && val)
	    return unpackVariant(val, deep);
	else
	    return val;
    case 'a':
	if (variant.is_of_type(new GLib.VariantType('a{?*}'))) {
	    // special case containers
	    let ret = { };
	    let nElements = variant.n_children();
	    for (let i = 0; i < nElements; i++) {
		// always unpack the dictionary entry, and always unpack
		// the key (or it cannot be added as a key)
		let val = unpackVariant(variant.get_child_value(i), deep);
		let key;
		if (!deep)
		    key = unpackVariant(val[0], true);
		else
		    key = val[0];
		ret[key] = val[1];
	    }
	    return ret;
	}
        if (variant.is_of_type(new GLib.VariantType('ay'))) {
            // special case byte arrays
            return variant.get_data_as_bytes().toArray();
        }

	// fall through
    case '(':
    case '{':
	let ret = [ ];
	let nElements = variant.n_children();
	for (let i = 0; i < nElements; i++) {
	    let val = variant.get_child_value(i);
	    if (deep)
		ret.push(unpackVariant(val, deep));
	    else
		ret.push(val);
	}
	return ret;
    }

    throw new Error('Assertion failure: this code should not be reached');
}
