package cherry.tools;

import hxd.fs.FileInput;
import haxe.macro.Expr;

class ResTools {
  /**
    Equivalent to `Res.initPak` but also works with JS.
    
    Example usage:
    ```haxe
    // In your App class
    override function loadAssets(onLoaded:() -> Void)
    {
      ResTools.initPakAuto(onLoaded, (p) -> trace(p));
    }
    ```
    
    @param file Optional resource folder path. Defaults to value in `resourcesPath` or `res`.
    @param onReady `Void->Void` Required callback when resources are loaded. Because JS can't load pak instantly,
    it is done asynchronously and callback is called when Res is initialised.
    Called instantly on non-JS target.
    @param onProgress `Float->Void` Optional callback for loading progress. Passed value is a percentile from 0 to 1.
    Never called on non-JS target.
  **/
  public static macro function initPakAuto(?file:String, onReady:ExprOf<Void->Void>, ?onProgress:ExprOf<Float->Void>) {
    if( file == null )
      file = haxe.macro.Context.definedValue("resourcesPath");
    if( file == null )
      file = "res";
    // TODO: Config stuff
    #if (!display || heeps_make_pak_on_display)
    hxd.fmt.pak.Build.make(sys.FileSystem.fullPath(file), file, true);
    #end
    
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
        ${onReady}();
      }
    }
  }
  
}