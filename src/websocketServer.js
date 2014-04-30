const Lang = imports.lang;

const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Soup = imports.gi.Soup;
const Util = imports.util;

/* NoFlo glue */
let NoFloContext = imports['noflo-runtime-base'];
NoFloContext.setTimeout = function(cb, time) {
    return GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
        cb();
        return false;
    }, null, null);
};
NoFloContext.setInterval = function(cb, time) {
    return GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
        cb();
        return true;
    }, null, null);
};
NoFloContext.clearTimeout = function(id) {
    if (id > 0)
        GLib.source_remove(id);
};
NoFloContext.clearInterval = NoFloContext.clearTimeout;
const NoFlo = NoFloContext.require('noflo');
const NoFloRuntimeBase = NoFloContext.require('noflo-runtime-base/src/Base.js');

/**/

let WebProtoRuntime = function(args) {
    this.connection = args.connection;
    this.prototype = NoFloRuntimeBase.prototype;
    this.prototype.constructor.apply(this, arguments);
    this.receive = this.prototype.receive;

    this.send = function(protocol, topic, payload, context) {
        if (!this.connection)
            return;
        this.connection.sendMessage(JSON.stringify({
            protocol: protocol,
            command: topic,
            payload: payload,
        }));
    };
};

/**/

const WebProtoServer = new Lang.Class({
    Name: 'WebProtoServer',

    _init: function(args) {
        this.connection = null;
        this.runtime = new WebProtoRuntime({ connection: this,
                                             baseDir: '/noflo-runtime-base', });

        this.signals = [];

        this.server = new Soup.Server({ port: args.port, });
        this.server.add_websocket_handler(null, null, null,
                                          Lang.bind(this, this.mainHandler));
    },

    mainHandler: function(server, path, connection, client) {
        if (this.connection != null) {
            this.connection.close(0, null);
            this.clientDisconnected(this.connection);
            log('A client is already connected, bye-bye to the previous one.');
            //return;
        }

        log('client connected to ' + path);

        this.connection = connection;

        this.signals.push(this.connection.connect('open', Lang.bind(this, this.clientConnected)));
        this.signals.push(this.connection.connect('message', Lang.bind(this, this.clientMessage)));
        this.signals.push(this.connection.connect('close', Lang.bind(this, this.clientDisconnected)));
    },

    clientConnected: function(conn) {
        log('client connected');
    },

    clientMessage: function(conn, opcode, message) {
        if (opcode != 1)
            return;

        //log('got client message: ' + message.get_data());
        let contents = JSON.parse('' + message.get_data());

        this.runtime.receive(contents.protocol,
                             contents.command,
                             contents.payload,
                             this);
    },

    clientDisconnected: function(conn) {
        log('client disconnected');
        if (conn != this.connection)
            return;

        for (let i in this.signals)
            this.connection.disconnect(this.signals[i]);
        this.signals = [];
        this.connection = null;
    },

    sendMessage: function(message) {
        //log('sending message: ' + message);
        this.connection.send_text(message);
    },

    /**/

    start: function() {
        this.server.run_async();
    },

    stop: function() {
        this.server.disconnect();
    },
});


let server = null;
let getDefault = function() {
    if (server == null) {
        server = new WebProtoServer({ port: 5555, });
    }

    return server;
};
