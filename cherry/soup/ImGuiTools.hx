package cherry.soup;

//==============================================================
// Warning: I use Spitko fork of imgui, as it has more features.
//==============================================================
import haxe.ds.Either;
import hxd.Key;
#if !macro
import haxe.io.Bytes;
import h3d.mat.Texture;
import h3d.Vector;
import h2d.col.Point;
import h2d.Tile;
#if hlimgui

import imgui.ImGuiDrawable;
import imgui.types.ImFontAtlas;
import imgui.ImGuiUtils;

import imgui.ImGui;
import hl.NativeArray;

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
typedef ITC = ImTypeCache;

@:forwardStatics
abstract ImGuiTools(imgui.ImGui) {
  
  // Instances of vec2/4 in order to avoid extra allocs.
  @:deprecated("Use ImTypeCache")
  public static var point:ImVec2 = ImVec2.get();
  @:deprecated("Use ImTypeCache")
  public static var point2:ImVec2 = ImVec2.get();
  @:deprecated("Use ImTypeCache")
  public static var point3:ImVec2 = ImVec2.get();
  @:deprecated("Use ImTypeCache")
  public static var point4:ImVec2 = ImVec2.get();
  @:deprecated("Use ImTypeCache")
  public static var vec:ImVec4S = ImVec4S.get();
  @:deprecated("Use ImTypeCache")
  public static var vec2:ImVec4S = ImVec4S.get();
  
  public static var arrSingle1:IMArray<Single> = new IMArray(1);
  public static var arrSingle2:IMArray<Single> = new IMArray(2);
  public static var arrSingle3:IMArray<Single> = new IMArray(3);
  public static var arrSingle4:IMArray<Single> = new IMArray(4);
  
  public static var arrDouble1:IMArray<Float> = new IMArray(1);
  public static var arrDouble2:IMArray<Float> = new IMArray(2);
  public static var arrDouble3:IMArray<Float> = new IMArray(3);
  public static var arrDouble4:IMArray<Float> = new IMArray(4);
  
  public static var arrInt1:IMArray<Int> = new IMArray(1);
  public static var arrInt2:IMArray<Int> = new IMArray(2);
  public static var arrInt3:IMArray<Int> = new IMArray(3);
  public static var arrInt4:IMArray<Int> = new IMArray(4);
  
  // That array have to be kept alive for duration of font creation, so to avoid it being GCd we statically store it.
  static var forkAwesomeGlyphRanges: hl.NativeArray<hl.UI16>;
  /**
    Add Fork Awesome font with its glyph range limiters in order to facilitate font merging.
  **/
  public static function getForkAwesomeRanges(): hl.NativeArray<hl.UI16> {
    if (forkAwesomeGlyphRanges == null) {
      forkAwesomeGlyphRanges = new hl.NativeArray<hl.UI16>(2);
      forkAwesomeGlyphRanges[0] = 0xf000;
      forkAwesomeGlyphRanges[1] = 0xff00; // Technically maximum is 0xf35f, but we're going for safety margin of upcoming versions.
    }
    return forkAwesomeGlyphRanges;
  }
  
  public static function addForkAwesome(fonts: ImFontAtlas, pathToTtf: String, size: Single, config: ImFontConfig = null): ImFont {
    if (config == null) config = new ImFontConfig();
    @:privateAccess config.GlyphOffset.y = 1;
    return fonts.addFontFromFileTTF(pathToTtf, size, config, getForkAwesomeRanges());
  }
  
  public static function quickFontSetup(?mainFont:Either<String, hxd.res.Any>, ?forkAwesomeFont:Either<String, hxd.res.Any>, size: Single, ?iconSize: Single): ImFont {
    // TODO: config provide
    var fonts = IG.getFontAtlas();
    var fnt =
      if (mainFont != null) {
        var cfg: ImFontConfig = new ImFontConfig().setOversample(1, 1);//{ OversampleH: 6, OversampleV: 3 };
        switch (mainFont) {
          case Left(path):
            fonts.addFontFromFileTTF(path, size, cfg);
          case Right(res):
            if (Std.isOfType(res.entry, hxd.fs.LocalFileSystem.LocalEntry)) {
              fonts.addFontFromFileTTF(@:privateAccess (untyped res.entry: hxd.fs.LocalFileSystem.LocalEntry).file, size, cfg);
            } else {
              var b = res.entry.getBytes();
              fonts.addFontFromMemoryTTF(b.getData(), b.length, size, cfg);
            }
        }
      }
      else fonts.addFontDefault();
    if (forkAwesomeFont != null) {
      var s: Single = iconSize == null ? size : iconSize;
      var cfg = new ImFontConfig().setOversample(1, 1).setMergeMode();
      switch (forkAwesomeFont) {
        case Left(path):
          addForkAwesome(fonts, path, s, cfg);
        case Right(res):
          if (Std.isOfType(res.entry, hxd.fs.LocalFileSystem.LocalEntry)) {
            addForkAwesome(fonts, @:privateAccess (untyped res.entry: hxd.fs.LocalFileSystem.LocalEntry).file, s, cfg);
          } else {
            var b = res.entry.getBytes();
            fonts.addFontFromMemoryTTF(b.getData(), b.length, size, cfg, getForkAwesomeRanges());
          }
      }
    }
    buildAndSetFontTexture(fonts);
    return fnt;
  }
  
  public static function buildAndSetFontTexture(fonts: ImFontAtlas) {
    // TODO: Fix cursors?
    fonts.build();
    var data = new ImFontTexData();
    fonts.getTexDataAsRGBA32(data);
    fonts.clearTexData();
    var pixels = new hxd.Pixels(data.width, data.height, data.buffer.toBytes(data.width * data.height * 4), RGBA);
    fonts.setTexId(ImGuiDrawableBuffers.instance.font_texture = Texture.fromPixels(pixels));
  }
  
  // public static function image(tile:Tile, ?tint: Int, ?borderColor: Int) @:privateAccess {
  //   point.set(tile.width, tile.height);
  //   point2.set(tile.u, tile.v);
  //   point3.set(tile.u2, tile.v2);
  //   if (tint != null) vec.setColor(tint);
  //   else vec.set(1, 1, 1, 1);
  //   if (borderColor != null) vec2.setColor(borderColor);
  //   else vec2.set(1, 1, 1, 1);
  //   return ImGui.image(tile.getTexture(), point, point2, point3, vec, vec2);
  // }
  // public static function imageButton(tile:Tile, framePadding:Int = -1, ?bg:Int, ?tint:Int) @:privateAccess {
  //   point.set(tile.width, tile.height);
  //   point2.set(tile.u, tile.v);
  //   point3.set(tile.u2, tile.v2);
  //   if (bg != null) vec.setColor(bg);
  //   else vec.set(0,0,0,0);
  //   if (tint != null) vec2.setColor(tint);
  //   else vec2.set(1,1,1,1);
  //   return ImGui.imageButton(tile.getTexture(), point, point2, point3, framePadding, vec, vec2);
  // }
  
  public static function posInput<T:{ x:Float, y:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrDouble2;
    ImGui.inputDoubleN(label, vv.set2(target.x, target.y), format, flags);
    target.x = vv.x;
    target.y = vv.y;
  }
  
  public static function posInputObj(label:String, target:h2d.Object, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrDouble2;
    ImGui.inputDoubleN(label, vv.set2(target.x, target.y), format, flags);
    target.x = vv.x;
    target.y = vv.y;
  }
  
  public static function posInput3<T:{ x:Float, y:Float, z:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrDouble3;
    ImGui.inputDoubleN(label, vv.set3(target.x, target.y, target.z), format, flags);
    target.x = vv.x;
    target.y = vv.y;
    target.z = vv.z;
  }
  
  public static function posInput4<T:{ x:Float, y:Float, z:Float, w:Float }>(label:String, target:T, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrDouble4;
    vv[0] = target.x;
    vv[1] = target.y;
    vv[2] = target.z;
    vv[3] = target.w;
    ImGui.inputDoubleN(label, vv.set4(target.x, target.y, target.z, target.w), format, flags);
    target.x = vv.x;
    target.y = vv.y;
    target.z = vv.z;
    target.w = vv.w;
  }
  
  public static function posInputObj3(label:String, target:h3d.scene.Object, format:String = "%.3f", flags:ImGuiInputTextFlags = 0) {
    var vv = arrDouble3;
    ImGui.inputDoubleN(label, vv.set3(target.x, target.y, target.z), format, flags);
    target.x = vv.x;
    target.y = vv.y;
    target.z = vv.z;
  }
  
  public static inline function getBackgroundDrawListSceneScale(s2d: h2d.Scene) {
    return SceneDrawList.fromDrawList(ImGui.getBackgroundDrawList(), s2d);
  }
  
  public static function inputTextArray(label, texts:Array<String>, flags:ImGuiInputTextFlags = 0) {
    if (ImGui.collapsingHeader(label, ImGuiTreeNodeFlags.DefaultOpen)) {
      var idx = 0;
      while (idx < texts.length) {
        IG.pushIDInt(idx);
        var txt = texts[idx];
        if (IG.inputText("[" + idx +"]", txt, flags)) {
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
  
  /**
    Helper for when you need your text to be null if it's an empty string.
  **/
  public static function inputNullText(label: String, text: Ref<String>, flags: ImGuiInputTextFlags = 0, ?callback: ImGuiInputTextCallbackDataFunc) {
    if (text.get() == null) {
      text.set("");
      if (IG.inputText(label, text, flags, callback)) {
        if (text.get() == "") text.set(null);
        return true;
      }
      return false;
    } else return IG.inputText(label, text, flags, callback);
  }
  /**
    Helper for when you need your text to be null if it's an empty string.
  **/
  public static function inputNullTextMultiline(label: String, text: Ref<String>, ?size: ImVec2, flags: ImGuiInputTextFlags = 0, ?callback: ImGuiInputTextCallbackDataFunc) {
    if (text.get() == null) {
      text.set("");
      if (IG.inputTextMultiline(label, text, size, flags, callback)) {
        if (text.get() == "") text.set(null);
        return true;
      }
      return false;
    } else return IG.inputTextMultiline(label, text, size, flags, callback);
  }
  
  // Quick dock space setup
  public static function beginSimpleDock(dock_id:String, width:Int, height:Int, flags: ImGuiDockNodeFlags = ImGuiDockNodeFlags.NoDockingInCentralNode | ImGuiDockNodeFlags.PassthruCentralNode) {
    IG.pushStyleVar(ImGuiStyleVar.WindowRounding, 0);
    IG.pushStyleVar(ImGuiStyleVar.WindowBorderSize, 0);
    IG.pushStyleVar(ImGuiStyleVar.WindowPadding, ITC.vec2(0,0));
    IG.setNextWindowPos(ITC.vec2(0, 0));
    IG.setNextWindowSize(ITC.vec2(width, height));
    IG.setNextWindowBgAlpha(0);
    IG.begin(dock_id, null, ImGuiWindowFlags.NoDocking | ImGuiWindowFlags.NoBackground | ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.MenuBar
        | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoCollapse | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoMove
        | ImGuiWindowFlags.NoBringToFrontOnFocus | ImGuiWindowFlags.NoNavFocus);
    IG.popStyleVar(3);
    var dockID = IG.getID(dock_id);
    IG.dockSpace(dockID, null, flags);
    
  }
  
  public static inline function endSimpleDock() {
    IG.end();
  }
  
  public static function quickClipper<T>(array: Array<T>, itemHeight: Single = -1.0, render: (v:T, idx: Int, clipper:ImGuiListClipper)->Void ) {
    var c = new ImGuiListClipper();
    c.begin(array.length, itemHeight);
    
    while (c.step()) {
      for (i in c.displayStart...c.displayEnd) {
        render(array[i], i, c);
      }
    }
  }
  
  public static function quickComboBox<T>(label: String, current: Ref<T>, values: Array<T>, stringify: T->String, flags: ImGuiComboFlags = 0, selectableFlags: ImGuiSelectableFlags = 0): Bool {
    var changed = false;
    var cur = current.get();
    if (IG.beginCombo(label, stringify(cur), flags)) {
      for (val in values) {
        if (IG.selectable(stringify(val), cur == val, selectableFlags)) {
          changed = true;
          current.set(val);
        }
      }
      IG.endCombo();
    }
    return changed;
  }
  
  public static function stringComboBox(label: String, current: Ref<String>, values: Array<String>, previewValue: String = "", flags: ImGuiComboFlags = 0, selectableFlags: ImGuiSelectableFlags = 0): Bool {
    var changed = false;
    var cur = current.get();
    if (IG.beginCombo(label, cur == null ? previewValue : cur, flags)) {
      for (val in values) {
        if (IG.selectable(val, cur == val, selectableFlags)) {
          changed = true;
          current.set(val);
        }
      }
      IG.endCombo();
    }
    return changed;
  }
  
  // Warning: Can't handle complex enums that need arguments
  public static function enumComboBox<T: EnumValue>(label: String, e: Enum<T>, current: T, ?isChanged: Ref<Bool>, previewValue: String = "Unknown enum", flags: ImGuiComboFlags = 0, selectableFlags: ImGuiSelectableFlags = 0): T {
    if (isChanged != null) isChanged.set(false);
    if (IG.beginCombo(label, current == null ? previewValue : current.getName(), flags)) {
      var values: Array<T> = cast e.createAll();
      for (val in values) {
        if (IG.selectable(val.getName(), current != null && val.match(current), selectableFlags)) {
          if (isChanged != null) isChanged.set(true);
          current = val;
        }
      }
      IG.endCombo();
    }
    return current;
  }
  
  public static function doConfirm(text: String, name: String = "Confirm", callback: (Bool)->Void) {
    if (IG.beginPopupModal(name)) {
      IG.text(text);
      var w = IG.getWindowWidth() * .5;
      var btnSize = 100;// IG.calcTextSize("Yes").x + 8;
      IG.setCursorPosX(w - btnSize - 4);
      var size = ITC.vec2(btnSize, 0);
      if (IG.button("No", size)) {
        IG.closeCurrentPopup();
        callback(false);
      }
      IG.sameLine(w + 4);
      if (IG.button("Yes", size)) {
        IG.closeCurrentPopup();
        callback(true);
      }
      IG.endPopup();
    }
  }
  
  inline static function iid(val: String):Int return IG.getID(val);
}
#end
#end