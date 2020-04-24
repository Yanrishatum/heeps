package cherry.macro;

import haxe.macro.Expr;

class Helper {
  
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