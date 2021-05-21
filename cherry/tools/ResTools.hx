package cherry.tools;

import hxd.fs.FileInput;
import haxe.macro.Expr;

class ResTools {
  
  public static macro function initPakAuto(?file:String, onReady:ExprOf<Void->Void>, ?onProgress:ExprOf<Float->Void>) {
    if( file == null )
      file = haxe.macro.Context.definedValue("resourcesPath");
    if( file == null )
      file = "res";
    // TODO: Config stuff
    hxd.fmt.pak.Build.make(sys.FileSystem.fullPath(file), file, true);
    
    if (haxe.macro.Context.definedValue("target.name") == "js") {
      var maxPaks = 1;
      while (true) {
        if (!sys.FileSystem.exists(file + maxPaks + ".pak")) break;
        maxPaks++;
      }
      var step = 1 / maxPaks;
      var progressExpr = if (onProgress != null) macro loader.onProgress = (c, m) -> ${onProgress}(c / m * $v{step});
      else macro {};
      return macro {
        var file = $v{file};
        var pak = new hxd.fmt.pak.FileSystem();
        var i = 0;
        var loader = new hxd.net.BinaryLoader(file + ".pak");
        $progressExpr;
        loader.onLoaded = (data) -> {
          pak.addPak(new hxd.fmt.pak.FileSystem.FileInput(data));
          if (++i == $v{maxPaks}) {
            hxd.Res.loader = new hxd.res.Loader(pak);
            ${onReady}();
          } else {
            @:privateAccess loader.url = file + (i) + ".pak";
            loader.load();
          }
        }
        loader.onError = (e) -> {
          throw e;
          // if (i == 0) throw e;
          // else {
          //   hxd.Res.loader = new hxd.res.Loader(pak);
          //   ${onReady}();
          // }
        }
        loader.load();
      }
    } else {
      return macro {
        var file = $v{file};
        var pak = new hxd.fmt.pak.FileSystem();
        pak.loadPak(file + ".pak");
        var i = 1;
        while( true ) {
          if( !hxd.File.exists(file + i + ".pak") ) break;
          pak.loadPak(file + i + ".pak");
          i++;
        }
        hxd.Res.loader = new hxd.res.Loader(pak);
      }
    }
  }
  
}