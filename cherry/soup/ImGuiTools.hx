package cherry.soup;

//==============================================================
// Warning: I use Spitko fork of imgui, as it has more features.
//==============================================================

import haxe.io.Bytes;
import h3d.mat.Texture;
import h3d.Vector;
import h2d.col.Point;
import h2d.Tile;
#if hlimgui

import imgui.ImGuiDrawable;

import imgui.ImGui;
import hl.NativeArray;

private class ImVec2Impl {
  public var x:Single;
  public var y:Single;
  
  public function new() { x = 0; y = 0; }
  public function set(x:Float, y:Float) {
    this.x = x;
    this.y = y;
    return this;
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
    return this;
  }
  public function setColor(c:Int) {
    this.x = (c >> 16 & 0xff) / 0xff;
    this.y = (c >> 8  & 0xff) / 0xff;
    this.z = (c       & 0xff) / 0xff;
    this.w = (c >> 24 & 0xff) / 0xff;
    return this;
  }
}

@:forward @:arrayAccess
abstract IMArray<T:Float & Single>(NativeArray<T>) to NativeArray<T> from NativeArray<T> {
  
  public inline function new(size:Int) this = new NativeArray(size);
  
  public var x(get, set):T;
  inline function get_x():T return this[0];
  inline function set_x(v:T):T return this[0] = v;
  public var y(get, set):T;
  inline function get_y():T return this[1];
  inline function set_y(v:T):T return this[1] = v;
  public var z(get, set):T;
  inline function get_z():T return this[2];
  inline function set_z(v:T):T return this[2] = v;
  public var w(get, set):T;
  inline function get_w():T return this[3];
  inline function set_w(v:T):T return this[3] = v;
  
  public inline function set1(x:T):IMArray<T> {
    this[0] = x;
    return this;
  }
  
  public inline function set2(x:T, y:T):IMArray<T> {
    this[0] = x;
    this[1] = y;
    return this;
  }
  
  public inline function set3(x:T, y:T, z:T):IMArray<T> {
    this[0] = x;
    this[1] = y;
    this[2] = z;
    return this;
  }
  
  public inline function set4(x:T, y:T, z:T, w:T):IMArray<T> {
    this[0] = x;
    this[1] = y;
    this[2] = z;
    this[3] = w;
    return this;
  }
  
  @:arrayAccess inline function _get(key:Int) return this[key];
  @:arrayAccess inline function _set(key:Int, value:T) return this[key] = value;
  
}

typedef IG = ImGuiTools;

@:forwardStatics
abstract ImGuiTools(imgui.ImGui) {
  
  #if macro
  /**
    A bugfix for HL not handling hl.Ref of non-local variables properly.
    
    How to use:
    ```haxe
    IG.wref(IG.begin("Name", _), isOpen);
    ```
    Replace all reference vars as _ in the first argument as imgui call and then list the reference to it afterwards.
  **/
  public static macro function wref(expr:haxe.macro.Expr, names:Array<haxe.macro.Expr>):haxe.macro.Expr {
    cherry.soup.ImGuiMacro.wref(expr, names);
  }
  #end
  
  // Instances of vec2/4 in order to avoid extra allocs.
  public static var point:ImVec2Impl = new ImVec2Impl();
  public static var point2:ImVec2Impl = new ImVec2Impl();
  public static var point3:ImVec2Impl = new ImVec2Impl();
  public static var vec:ImVec4Impl = new ImVec4Impl();
  public static var vec2:ImVec4Impl = new ImVec4Impl();
  
  public static var arrSingle4:IMArray<Single> = new IMArray(4);
  public static var arrSingle3:IMArray<Single> = new IMArray(3);
  public static var arrSingle2:IMArray<Single> = new IMArray(2);
  public static var arrSingle1:IMArray<Single> = new IMArray(1);
  public static var arrInt1:IMArray<Int> = new IMArray(1);
  public static var arrInt2:IMArray<Int> = new IMArray(2);
  public static var arrInt3:IMArray<Int> = new IMArray(3);
  public static var arrInt4:IMArray<Int> = new IMArray(4);
  
  
  public static function image(tile:Tile, ?tint: Int, ?borderColor: Int) @:privateAccess {
    point.set(tile.width, tile.height);
    point2.set(tile.u, tile.v);
    point3.set(tile.u2, tile.v2);
    if (tint != null) vec.setColor(tint);
    else vec.set(1, 1, 1, 1);
    if (borderColor != null) vec2.setColor(borderColor);
    else vec2.set(1, 1, 1, 1);
    return ImGui.image(tile.getTexture(), point, point2, point3, vec, vec2);
  }
  public static function imageButton(tile:Tile, framePadding:Int = -1, ?bg:Int, ?tint:Int) @:privateAccess {
    point.set(tile.width, tile.height);
    point2.set(tile.u, tile.v);
    point3.set(tile.u2, tile.v2);
    if (bg != null) vec.setColor(bg);
    else vec.set(0,0,0,0);
    if (tint != null) vec2.setColor(tint);
    else vec2.set(1,1,1,1);
    return ImGui.imageButton(tile.getTexture(), point, point2, point3, framePadding, vec, vec2);
  }
  
  public static function inputDouble(label : String, v : Float, step : Float = 0.0, step_fast : Float = 0.0, format : String = "%.6f", flags : ImGuiInputTextFlags = 0):Float {
    ImGui.inputDouble(label, v, step, step_fast, format, flags);
    return v;
  }
  
  public static function posInput<T:{ x:Float, y:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle2;
    ImGui.inputFloat2(label, vv.set2(target.x, target.y), format, flags);
    target.x = vv.x;
    target.y = vv.y;
  }
  
  public static function posInputObj(label:String, target:h2d.Object, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle2;
    ImGui.inputFloat2(label, vv.set2(target.x, target.y), format, flags);
    target.x = vv.x;
    target.y = vv.y;
  }
  
  public static function posInput3<T:{ x:Float, y:Float, z:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle3;
    ImGui.inputFloat3(label, vv.set3(target.x, target.y, target.z), format, flags);
    target.x = vv.x;
    target.y = vv.y;
    target.z = vv.z;
  }
  
  public static function posInput4<T:{ x:Float, y:Float, z:Float, w:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle4;
    vv[0] = target.x;
    vv[1] = target.y;
    vv[2] = target.z;
    vv[3] = target.w;
    ImGui.inputFloat3(label, vv.set4(target.x, target.y, target.z, target.w), format, flags);
    target.x = vv.x;
    target.y = vv.y;
    target.z = vv.z;
    target.w = vv.w;
  }
  
  public static function posInputObj3(label:String, target:h3d.scene.Object, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrSingle3;
    ImGui.inputFloat3(label, vv.set3(target.x, target.y, target.z), format, flags);
    target.x = vv.x;
    target.y = vv.y;
    target.z = vv.z;
  }
  
  public static function sliderDouble(label : String, v : Single, v_min : Single, v_max : Single, format : String = "%.3f", flags : ImGuiSliderFlags = 0):Float {
    ImGui.sliderFloat(label, v, v_min, v_max, format, flags);
    return v;
  }
  
  static var textCache:hl.Bytes = new hl.Bytes(1024*2);
  static var textCacheSize:Int = 1024*2;
  public static function inputText(label:String, text:hl.Ref<String>, flags:ImGuiInputTextFlags = 0, maxSize:Int = 1024):Bool @:privateAccess {
    maxSize <<= 1;
    var txt = text.get();
    if (txt == null) txt = "";
    if (maxSize < ((txt.length+128)<<1)) {
      // Add extra spacing in case text is changed beyond current size
      maxSize = (txt.length+128)<<1;
    }
    if (textCacheSize < maxSize) {
      textCache = new hl.Bytes(maxSize);
      textCacheSize = maxSize;
    }
    // Convert utf-16 text into utf-8. Sadly HL API don't let me to specify into which Bytes it should write it, hence extra blitting.
    var size = 0;
    var u8 = txt.bytes.utf16ToUtf8(txt.length<<1, size);
    textCache.blit(0, u8, 0, size);
    textCache[size] = 0;
    if (ImGui.inputText(label, textCache, textCacheSize, flags)) {
      // Only convert back if changed.
      var u16 = textCache.utf8ToUtf16(0, size);
      text.set(String.__alloc__(u16, size>>1));
      return true;
    }
    return false;
  }
  
  public static function inputTextArray(label, texts:Array<String>, flags:ImGuiInputTextFlags = 0, maxSize: Int = 1024) {
    if (ImGui.collapsingHeader(label, ImGuiTreeNodeFlags.DefaultOpen)) {
      var idx = 0;
      while (idx < texts.length) {
        IG.pushID3(idx);
        var txt = texts[idx];
        if (IG.inputText("[" + idx +"]", txt, flags, maxSize)) {
          texts[idx] = txt;
        }
        IG.sameLine(0, 3);
        if (ImGui.smallButton("-")) {
          texts.splice(idx, 1);
          idx--;
        }
        IG.sameLine(0, 3);
        if (ImGui.smallButton("+")) {
          texts.insert(idx+1, "");
        }
        ImGui.popID();
        idx++;
      }
      if (texts.length == 0) {
        IG.text("(Empty array)");
        IG.sameLine(0, 3);
        if (IG.smallButton("+")) {
          texts.push("");
        }
      }
    }
  }
  
  public static function beginSimpleDock(dock_id:String, width:Int, height:Int) {
    IG.pushStyleVar(ImGuiStyleVar.WindowRounding, 0);
    IG.pushStyleVar(ImGuiStyleVar.WindowBorderSize, 0);
    IG.pushStyleVar2(ImGuiStyleVar.WindowPadding, IG.point.set(0,0));
    IG.setNextWindowPos(IG.point.set(0, 0));
    IG.setNextWindowSize(IG.point.set(width, height));
    IG.setNextWindowBgAlpha(0);
    IG.begin(dock_id, null, ImGuiWindowFlags.NoDocking | ImGuiWindowFlags.NoBackground | ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.MenuBar
        | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoCollapse | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoMove
        | ImGuiWindowFlags.NoBringToFrontOnFocus | ImGuiWindowFlags.NoNavFocus);
    IG.popStyleVar(3);
    var dockID = IG.getID(dock_id);
    IG.dockSpace(dockID, null, ImGuiDockNodeFlags.NoDockingInCentralNode | ImGuiDockNodeFlags.PassthruCentralNode);
    
  }
  
  public static inline function endSimpleDock() {
    IG.end();
  }
  
}
#end