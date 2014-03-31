library forcejade;

import "dart:io";
import "dart:async";
import "package:forcemvc/force_mvc.dart";
import "dart:isolate";
import "package:jaded/jaded.dart" as jade;

class JadeRender extends ForceViewRender{
  String viewDir;
  bool onFlyCompile;
  SendPort _sPort;
  ReceivePort _rPort;
  int idCpt;
  Map<int,Completer> completers;

  JadeRender({this.viewDir :"../views"}) : super(){
    _sPort = null;
    _rPort = null;
    idCpt = 0;
    completers = new Map<int,Completer>();
    _rPort = new ReceivePort();
    runIsolate();
  }

  Future<String> render(String view, model) {
    Completer<String> comp = new Completer<String>();
    String filePath = "$viewDir$view.jade".replaceAll("\\","/");
    completers[idCpt] = comp;
    _sPort.send([idCpt,filePath,model]);
    idCpt++;
    return comp.future;
  }

  void runIsolate() {
    compile(viewDir : this.viewDir);
    Isolate.spawnUri(new Uri.file("$viewDir/jaded.views.dart"), [], _rPort.sendPort);
    _rPort.listen((message){
      if(_sPort == null){
        _sPort = message;
      }else{
        completers[message[0]].complete(message[1]);
        completers.remove(message[0]);
      }
    });

  }

  static void compile({String viewDir : "../views"}){
    var jadeTemplates = jade.renderDirectory(viewDir);
    jadeTemplates = jadeTemplates.replaceFirst("\n","\nimport 'dart:isolate';\n");
    var isolateWrapper =
    """
  $jadeTemplates

  main(List args, SendPort replyTo) {
    ReceivePort rPort = new ReceivePort();
    replyTo.send(rPort.sendPort);
    rPort.listen((value){
      replyTo.send([value[0],JADE_TEMPLATES[value[1]](value[2])]);
    });
  }
  """;
    new File("$viewDir/jaded.views.dart").writeAsStringSync(isolateWrapper);
  }
}