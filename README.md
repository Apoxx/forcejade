Force Jade
==========

A Jade Template Engine plugin for [ForceMVC] using [Jaded].


[ForceMVC]: http://pub.dartlang.org/packages/forcemvc
[Jaded]: https://github.com/dartist/jaded

Usage example:

    import "package:forcemvc/force_mvc.dart";
    import "package:forcejade/forcejade.dart";

    void main(){
      WebServer server = new WebServer();
      server.viewRender = new JadeRender();
      server.start();
    }

    @Controller()
    class RequestHandler{
      @RequestMapping(value: "/")
      String index(ForceRequest req, Model model){
        return "index";
      }
    }

You can set the devMode attribute to true when you call the JadeRender constructor, so the server recompiles the views folder automatically on each render request.
That way, you avoid the need to restart the server each time you make a modification in the jade files at cost of slower requests.

    server.viewRender = new JadeRender(devMode: true);

You have to explicitly specify the package-root when you start your server to avoid path bugs:

    dart --package-root=packages/ server.dart
