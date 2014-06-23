const Lang = imports.lang;

const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Soup = imports.gi.Soup;
const Path = imports.path;
const Utils = imports.utils;

const NoFlo = imports.noflo;

/**/

let WebProtoRuntime = function(options) {
    this.connection = options.connection;
    delete options.connection;
    this.prototype = NoFlo.RuntimeBase.prototype;
    this.prototype.constructor.apply(this, [options]);
    this.receive = this.prototype.receive;

    this.send = function(protocol, topic, payload, context) {
        if (!this.connection)
            return;
        if (topic == 'error')
            this.connection.sendMessage(JSON.stringify({
                protocol: protocol,
                command: topic,
                payload: { message: payload.message },
            }));
        else
            this.connection.sendMessage(JSON.stringify({
                protocol: protocol,
                command: topic,
                payload: payload,
            }));
    };
};

/**/

const ComponentLoader = imports.componentLoader.ComponentLoader;

/**/

const WebProtoServer = new Lang.Class({
    Name: 'WebProtoServer',

    _init: function(args) {
        this.connection = null;
        this.runtime = new WebProtoRuntime({ connection: this,
                                             baseDir: '/noflo-runtime-base',
                                             type: 'noflo-nodejs', });

        this.runtime.component.loaders = {
            '/noflo-runtime-base': new ComponentLoader({
                baseDir: '/noflo-runtime-base',
                paths: [ 'library://components',
                         'local://components', ],
            })
        };

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
