package cherry.soup;

import h3d.Vector;
import h2d.col.Point;
import h2d.Tile;
#if hlimgui

#if macro
import haxe.macro.Expr;
using haxe.macro.Tools;
#else
import imgui.ImGui;
import hl.NativeArray;

private class ImVec2Impl {
  public var x:Single;
  public var y:Single;
  
  public function new() { x = 0; y = 0; }
  public function set(x:Float, y:Float) {
    this.x = x;
    this.y = y;
  }
}

private class ImVec4Impl {
  
  public var x:Single;
  public var y:Single;
  public var z:Single;
  public var w:Single;
  
  public function new() { x = 0; y = 0; z = 0; w = 0; }
  public function set(x:Float, y:Float, z:Float, w:Float) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }
  public function setColor(c:Int) {
    this.x = (c >> 16 & 0xff) / 0xff;
    this.y = (c >> 8  & 0xff) / 0xff;
    this.z = (c       & 0xff) / 0xff;
    this.w = (c >> 24 & 0xff) / 0xff;
  }
}

typedef IG = ImGuiTools;
#end

class ImGuiTools {
  
  public static macro function wref(expr:Expr, names:Array<Expr>):Expr {
    var tmps:Array<String> = [];
    var tmpDecl:Array<Expr> = [];
    var tmpAssign:Array<Expr> = [];
    for (n in names) {
      var tmpName = "__tmp_" + tmps.length;
      tmps.push(tmpName);
      tmpDecl.push(macro var $tmpName = $n);
      tmpAssign.push(macro $n = $i{tmpName});
    }
    function repl(e:Expr) {
      switch (e.expr) {
        case ECall(e, params):
          repl(e);
          for (p in params) repl(p);
        case EConst(Constant.CIdent("_")), EConst(Constant.CIdent("__")):
          e.expr = EConst(CIdent(tmps.shift()));
        case EField(e, field):
          repl(e);
        case EParenthesis(e):
          repl(e);
        case EBlock(exprs):
          for (e in exprs) repl(e);
        default:
      }
    }
    repl(expr);
    tmpDecl.push(macro var result = $e{expr});
    var result = tmpDecl.concat(tmpAssign);
    result.push(macro result);
    return macro $b{result};
  }
  
  #if !macro
  
  public static var point:ImVec2Impl = new ImVec2Impl();
  public static var point2:ImVec2Impl = new ImVec2Impl();
  public static var point3:ImVec2Impl = new ImVec2Impl();
  public static var vec:ImVec4Impl = new ImVec4Impl();
  public static var vec2:ImVec4Impl = new ImVec4Impl();
  public static var textures:Map<h3d.mat.Texture, Int> = [];
  public static function image(tile:Tile, ?tint:Int, ?borderColor:Int) @:privateAccess {
    var tex = tile.getTexture();
    var id = textures[tex];
    if (id == null) textures[tex] = id = imgui.ImGuiDrawable.ImGuiDrawableBuffers.instance.registerTexture(tex);
    point.set(tile.width, tile.height);
    point2.set(tile.u, tile.v);
    point3.set(tile.u2, tile.v2);
    if (tint != null) vec.setColor(tint);
    else vec.set(1,1,1,1);
    if (borderColor != null) vec2.setColor(borderColor);
    else vec2.set(1,1,1,1);
    return ImGui.image(id, point, point2, point3, vec, vec2);
  }
  public static function imageButton(tile:Tile, framePadding:Int = -1, ?bg:Int, ?tint:Int) @:privateAccess {
    var tex = tile.getTexture();
    var id = textures[tex];
    if (id == null) textures[tex] = id = imgui.ImGuiDrawable.ImGuiDrawableBuffers.instance.registerTexture(tex);
    point.set(tile.width, tile.height);
    point2.set(tile.u, tile.v);
    point3.set(tile.u2, tile.v2);
    if (bg != null) vec.setColor(bg);
    else vec.set(0,0,0,0);
    if (tint != null) vec2.setColor(tint);
    else vec2.set(1,1,1,1);
    return ImGui.imageButton(id, point, point2, point3, framePadding, vec, vec2);
  }
  
  public static function inputDouble(label : String, v : Float, step : Float = 0.0, step_fast : Float = 0.0, format : String = "%.6f", flags : ImGuiInputTextFlags = 0):Float {
    ImGui.inputDouble(label, v, step, step_fast, format, flags);
    return v;
  }
  
  public static var arrSingle4:NativeArray<Single> = new NativeArray(4);
  public static var arrSingle3:NativeArray<Single> = new NativeArray(3);
  public static var arrSingle2:NativeArray<Single> = new NativeArray(2);
  public static var arrSingle1:NativeArray<Single> = new NativeArray(1);
  public static var arrInt1:NativeArray<Int> = new NativeArray(1);
  public static var arrInt2:NativeArray<Int> = new NativeArray(2);
  public static var arrInt3:NativeArray<Int> = new NativeArray(3);
  public static var arrInt4:NativeArray<Int> = new NativeArray(4);
  
  public static function sliderInt(label:String, val:Int, v_min:Int, v_max:Int, format = "%d"):Int {
    var vv = arrInt1;
    vv[0]=val;
    ImGui.sliderInt(label, vv, v_min, v_max, format);
    return vv[0];
  }
  
  public static function posInput<T:{ x:Float, y:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle2;
    vv[0] = target.x;
    vv[1] = target.y;
    ImGui.inputFloat2(label, vv, format, flags);
    target.x = vv[0];
    target.y = vv[1];
  }
  
  public static function posInputObj(label:String, target:h2d.Object, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle2;
    vv[0] = target.x;
    vv[1] = target.y;
    ImGui.inputFloat2(label, vv, format, flags);
    target.x = vv[0];
    target.y = vv[1];
  }
  
  public static function posInput3<T:{ x:Float, y:Float, z:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle3;
    vv[0] = target.x;
    vv[1] = target.y;
    vv[2] = target.z;
    ImGui.inputFloat3(label, vv, format, flags);
    target.x = vv[0];
    target.y = vv[1];
    target.z = vv[2];
  }
  
  public static function posInput4<T:{ x:Float, y:Float, z:Float, w:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle4;
    vv[0] = target.x;
    vv[1] = target.y;
    vv[2] = target.z;
    vv[3] = target.w;
    ImGui.inputFloat3(label, vv, format, flags);
    target.x = vv[0];
    target.y = vv[1];
    target.z = vv[2];
    target.w = vv[3];
  }
  
  public static function posInputObj3(label:String, target:h3d.scene.Object, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle3;
    vv[0] = target.x;
    vv[1] = target.y;
    vv[2] = target.z;
    ImGui.inputFloat3(label, vv, format, flags);
    target.x = vv[0];
    target.y = vv[1];
    target.z = vv[2];
  }
  
  public static function sliderDouble(label : String, v : Single, v_min : Single, v_max : Single, format : String = "%.3f", power : Single = 1.0):Float {
    arrSingle1[0] = v;
    ImGui.sliderFloat(label, arrSingle1, v_min, v_max, format, power);
    return arrSingle1[0];
  }
  #end
}
#end