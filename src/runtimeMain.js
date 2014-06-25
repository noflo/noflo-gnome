const WebProtoServer = imports.websocketServer;
const Runtime = imports.runtime;

let start = function() {
    WebProtoServer.getDefault().start();
    Runtime.start();
};
