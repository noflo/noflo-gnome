const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;

let ComponentLoader = function(options) {
    let self = this;

    self.options = options;
    if (!self.options)
        self.options = {
            paths: [ '.' ],
        };

    let logFunc = function(name) {
        log('calling : ' +  name);
    };

    this.getModulePrefix = function(name) {
        logFunc(arguments.callee.toString());
        return '';
    };

    this.getModuleComponents = function(moduleName) {
        logFunc(arguments.callee.toString());
    };

    this.listComponents = function(callback) {
        logFunc('listComponents');
    };

    this.load = function(name, callback, delayed, metadata) {
        logFunc(arguments.callee.toString());
    };

    this.loadGraph = function(name, component, callback, delayed, metadata) {
        logFunc(arguments.callee.toString());
    };

    this.setIcon = function(name, instance) {
        logFunc(arguments.callee.toString());
    };

    this.getLibraryIcon = function(prefix) {
        logFunc(arguments.callee.toString());
    };

    this.registerComponent = function(packageId, name, cPath, callback) {
        logFunc(arguments.callee.toString());
    };

    this.registerGraph = function(packageId, name, gPath, callback) {
        logFunc(arguments.callee.toString());
    };

    this.setSource = function(packageId, name, source, language, callback) {
        logFunc(arguments.callee.toString());
    };

    this.getSource = function(name, callback) {
        logFunc(arguments.callee.toString());
    };
};
