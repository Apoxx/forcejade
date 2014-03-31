library forcejade;

import "dart:io";
import "dart:async";
import "package:forcemvc/force_mvc.dart";
import "dart:isolate";
import "package:jaded/jaded.dart" as jade;
import "package:isolate_pool/isolate_pool.dart";

class JadeRender extends ForceViewRender{
  String viewDir;
  bool devMode;
  IsolateWorker child;
  int idCpt;
  IsolatePool proxy;
  Map<int,Completer> completers;

  JadeRender({this.viewDir :"../views", this.devMode : false}) : super(){
    idCpt = 0;
    proxy = null;
    completers = new Map<int,Completer>();
    runIsolate();
  }

  Future<String> render(String view, model) {
    Completer<String> comp = new Completer<String>();
    var rend = (_){
      String filePath = "$viewDir$view.jade".replaceAll("\\","/");
      completers[idCpt] = comp;
      child.send({"idCpt": idCpt,"filePath": filePath,"model": model});
      idCpt++;
    };
    if(devMode)
      runIsolate().then(rend);
    else
      rend();
    return comp.future;
  }

  Future runIsolate() {
    Completer comp = new Completer();
    compile(viewDir : this.viewDir);
    if(proxy != null){
      completers.forEach((k,v) => completers[k].complete(""));
      completers.clear();
      proxy.close();
      proxy = null;
    }
    proxy = new IsolatePool();
    proxy.runIsolate(new Uri.file("$viewDir/jaded.views.dart"),[]).then((IsolateWorker child){
      this.child = child;
      child.stream.listen((IsolateMessage data){
        completers[data.message["idCpt"]].complete(data.message["html"]);
        completers.remove(data.message["idCpt"]);
      });
      comp.complete(true);
    });
    return comp.future;
  }

  static void compile({String viewDir : "../views"}){
    var jadeTemplates = jade.renderDirectory(viewDir);
    jadeTemplates = jadeTemplates.replaceFirst("\n",'\nimport "package:isolate_pool/isolate_pool.dart";\n');
    var isolateWrapper =
    """
  $jadeTemplates

  main(List args, SendPort replyTo) {
    var mirror = new IsolateWorker.isolateInit(replyTo);
    mirror.stream.listen((IsolateMessage msg){
      var value = msg.message;
      msg.source.send({"idCpt" : value["idCpt"],"html" : JADE_TEMPLATES[value["filePath"]](value["model"])});
    });
  }
  """;
    new File("$viewDir/jaded.views.dart").writeAsStringSync(isolateWrapper);
  }
}