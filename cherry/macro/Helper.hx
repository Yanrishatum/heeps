package cherry.macro;

#if macro
import haxe.macro.Expr;
import haxe.io.Path;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Compiler;
#end

class Helper {
  #if macro
  // Initialize macro part. 
  public static function init()
  {
    // Can't use that in HIDE plugins.
    if (Context.defined("hide_plugin")) return;
    
    Compiler.define("heeps_macro", "1");
    var fixups:Array<String> = new Array();
    for (k in hxd.res.Config.extensions.keys())
    {
      if (k.indexOf("gif") != -1)
      {
        fixups.push(k);
      }
    }
    for (f in fixups)
    {
      var v = hxd.res.Config.extensions.get(f);
      hxd.res.Config.extensions.remove(f);
      if (f == "gif") continue;
      var k =
      if (StringTools.endsWith(f, ",gif")) f.substr(0, f.length - 4);
      else StringTools.replace(f, "gif,", ",");
      hxd.res.Config.extensions.set(k, v);
    }
    hxd.res.Config.extensions.set("giff,gif", "cherry.res.GifImage");
    // hxd.res.Config.pairedExtensions.set("giff", "png,gif");
    hxd.res.Config.pairedExtensions.set("gif", "png");
    hxd.res.Config.extensions.set("atl", "cherry.res.AtlAtlas");
    hxd.res.Config.extensions.set("json", "cherry.res.JsonFile");
    hxd.fs.Convert.register(new cherry.fs.Convert.GifConvert());
    
    // Register converts
    Compiler.include("cherry.res.GifImage");
    Compiler.keep("cherry.res.GifImage");
    // trace(@:privateAccess hxd.fs.Convert.converts);
    // trace(@:privateAccess hxd.fs.FileConverter.extraConfigs);
    // trace(hxd.res.Config.extensions);
    // trace(hxd.res.Config.pairedExtensions);
    
    
    if (Context.definedValue("format-tiled") >= "2.0.0" || Context.defined("tiledhx"))
    {
      hxd.res.Config.extensions.set("tmx", "cherry.res.TiledMapFile");
    }
  }
  #end
  
  public static macro function getContent(file:String):ExprOf<String> {
    // trace(haxe.macro.Context.getLocalModule());
    var pos = haxe.macro.Context.currentPos();
    if (pos == null) return macro "";
    try {
      var path = haxe.io.Path.join([haxe.io.Path.directory(haxe.macro.PositionTools.getInfos(pos).file), file]);
      return macro $v{sys.io.File.getContent(path)};
    } catch (e:Dynamic) {
      haxe.macro.Context.fatalError("Could not find file: " + file, pos);
      return macro "";
    }
  }
}