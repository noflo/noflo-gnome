const WebProtoServer = imports.websocketServer;
const Mainloop = imports.mainloop;

WebProtoServer.getDefault().start();

Mainloop.run();
