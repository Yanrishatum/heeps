
import h2d.Text;
import h2d.col.IBounds;
import h2d.col.Bounds;
import h2d.col.Point;
import h2d.Interactive;
import h2d.Scene;
import h2d.RenderContext;
import h2d.Graphics;
import hxd.Event;
import hxd.Key;
import h2d.Object;
import h2d.Bitmap;
import haxe.Json;
import hide.Element;
import h2d.Tile;
import hide.comp.PropsEditor;
import haxe.io.Bytes;
import cherry.fmt.atl.Data;
import hide.view.FileView;
import cherry.plugins.atl.States;
import cherry.plugins.atl.Dragable;
import cherry.plugins.atl.CornerEdit;
import cherry.plugins.atl.SpriteEdit;
import cherry.plugins.atl.CreateTool as SpriteTool;
import cherry.plugins.generic.shaders.CheckerShader;
import cherry.plugins.generic.shaders.OutlineShader;

class AtlasEditor extends FileView {
  
  var scene:hide.comp.Scene;
  var props:PropsEditor;
  public var atlas:AtlasData;
  public var current:AtlasSprite;
  public var toolAction:CurrentAction;
  public var anim(get, never):AtlasAnim;
  @:keep function get_anim() {
    var a = atlas.anims[current.id];
    if (a.id != current.id) a.id = current.id;
    if (untyped a._id == null) untyped a._id = current.id;
    return a;
  }
  
  public var canvas:Interactive;
  var tool:SpriteTool;
  var sprites:Map<AtlasSprite, SpriteEdit>;
  var manageCtx:{ backgroundColor:Int, checker:Bool, whiteChecker:Bool, checkerSize:Int };
  
  final zooms = [0.2, 0.225, 0.25, 0.275, 0.3, 0.325, 0.35, 0.375, 0.4, 0.45, 0.5, 0.55, 0.60, 0.65, 0.7, 0.8, 0.9, 1,
    1.1, 1.2, 1.4, 1.6, 1.8, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 30];
  var zoom:Int;
  
  public var currZoom(get, never):Float;
  inline function get_currZoom() return zooms[zoom];
  
  public var scaler:Object;
  var grid:Bitmap;
  var gridShader:CheckerShader;
  var dragX:Float;
  var dragY:Float;
  public var tex:Bitmap;
  
  var undoChain = false;
  
  override function onDisplay()
  {
    zoom = zooms.indexOf(1.);
    super.onDisplay();
    element.html('
      <div class="flex" >
        <div class="heaps-scene" tabindex="1"></div>
        <div id="rightPanel" class="tabs"></div>
      </div>
    ');
    props = new PropsEditor(undo, null, element.find("#rightPanel"));
    props.saveDisplayKey = "cherry/atlasEditor";
    manageCtx = { backgroundColor: 0, checker: true, whiteChecker: false, checkerSize: 8 };
    sprites = [];
    // animCtx = {};
    
    scene = new hide.comp.Scene(false, config, null, element.find(".heaps-scene"));
    scene.onResize = onResize;
    scene.onUpdate = onUpdate;
    scene.onReady = init;
  }
  
  override public function onResize()
  {
    if (scaler != null) {
      tool.resize();
      scaler.setPosition(scene.width >> 1, scene.height >> 1);
      canvas.width = scene.width;
      canvas.height = scene.height;
      @:privateAccess scaler.syncPos();
      if (tex != null) {
        @:privateAccess tex.syncPos();
        for (s in sprites) s.resync(true);
      }
    }
    // TODO
  }
  
  function onUpdate(dt:Float) {
    if (current != null) {
      if (Key.isReleased(Key.DELETE)) {
        delete(current);
      } else {
        // if (Key.isReleased(Key.LEFT)) 
        // TODO: Arrow key move
      }
    }
    if (tool != null) {
      tool.visible = toolAction == None && Key.isDown(Key.SHIFT) || toolAction == Create;
    }
  }
  
  function dragTexture(e:Event) {
    tex.x += (e.relX - dragX) / zooms[zoom];
    tex.y += (e.relY - dragY) / zooms[zoom];
    grid.setPosition(tex.x, tex.y);
    dragX = e.relX;
    dragY = e.relY;
    @:privateAccess tex.syncPos();
    for (s in sprites) s.resync(false);
    if (e.kind == ERelease || e.kind == EReleaseOutside) scene.s2d.stopDrag();
  }
  
  public function onEvent(e:Event) {
    switch (e.kind) {
      case EPush:
        if (tex != null) {
          if (e.button == 0) {
            if (Key.isDown(Key.SHIFT)) {
              tool.start(e);
            } else {
              dragX = e.relX;
              dragY = e.relY;
              scene.s2d.startDrag(dragTexture, null, e);
            }
          }
        }
      case EMove:
      case ERelease:
        if (e.button == 1 && tex != null) {
          var pt = new Point(e.relX, e.relY);
          tex.globalToLocal(pt);
          var curs = [];
          for (s in atlas.sprites) if (s.x <= pt.x && s.x + s.width > pt.x && s.y <= pt.y && s.y + s.height > pt.y) curs.push(s);
          if (curs.length != 0) {
            new hide.comp.ContextMenu([for (s in curs) { label: s.id + "#" + s.index, click: focus.bind(s) }]);
          }
        }
      case EReleaseOutside:
      case EWheel:
        if (e.wheelDelta > 0) {
          zoom--;
          if (zoom < 0) zoom = 0;
        } else {
          zoom++;
          if (zoom >= zooms.length) zoom = zooms.length - 1;
        }
        var z = zooms[zoom];
        if (tex != null) tex.smooth = z < 1;
        scaler.setScale(z);
        @:privateAccess scaler.syncPos();
        @:privateAccess tex.syncPos();
        for (s in sprites) s.resync(true);
        // TODO: Position-aware
      default:
    }
  }
  
  function selCursor() {
    if (toolAction == None && Key.isDown(Key.SHIFT) || toolAction == Create) {
      hxd.System.setNativeCursor(Hide);
    } else {
      hxd.System.setNativeCursor(Move);
    }
  }
  
  function init()
  {
    // hxd.Window.getInstance().addEventTarget(onEvent);
    // hxd.res.Atlas
    // var fio = sys.io.File.read(getPath());
    // sprite = new cherry.fmt.asp.Reader(fio).read();
    // fio.close();
    canvas = new Interactive(scene.width, scene.height, scene.s2d);
    canvas.cursor = Callback(selCursor);
    canvas.onMove = (_) -> selCursor();
    canvas.onCheck = (_) -> selCursor();
    canvas.onPush = onEvent;
    canvas.onRelease = onEvent;
    canvas.onReleaseOutside = onEvent;
    canvas.onWheel = onEvent;
    canvas.enableRightButton = true;
    
    scaler = new Object(scene.s2d);
    scaler.x = scene.width >> 1;
    scaler.y = scene.height >> 1;
    
    grid = new Bitmap(Tile.fromColor(0xff0000), scaler);
    gridShader = new CheckerShader();
    grid.addShader(gridShader);
    
    tool = new SpriteTool(this, scene.s2d);
    atlas = new AtlasData();
    atlas.load(Json.parse(sys.io.File.getContent(getPath())));
    if (atlas.texturePath != null) initTexture(true);
    else {
      initSprites();
      initProps();
    }
  }
  
  function initTexture(isInit:Bool = false) {
    scene.loadTexture(state.path, atlas.texturePath, (t) -> {
      atlas.texture = Tile.fromTexture(t);
      initScene();
      if (isInit) initSprites();
      initProps();
    });
  }
  
  function initScene() {
    scaler.removeChildren();
    scaler.addChild(grid);
    tex = new Bitmap(atlas.texture, scaler);
    var t = atlas.texture.getTexture();
    tex.setPosition(-(t.width>>1), -(t.height>>1));
    grid.setPosition(tex.x, tex.y);
    grid.tile.setSize(t.width, t.height);
    // TODO: if (isInit) initSprites()
  }
  
  inline function storeEditorData(s:AtlasSprite) untyped {
    s._id = s.id;
  }
  
  function initSprites() {
    for (s in atlas.sprites) {
      var e = new SpriteEdit(this, s, scene.s2d);
      storeEditorData(s);
      sprites[s] = e;
    }
  }
  
  public function createTile(bounds:IBounds) {
    var s = new AtlasSprite("tile" + atlas.sprites.length); // TODO: Autoname
    storeEditorData(s);
    s.x = bounds.x;
    s.y = bounds.y;
    s.width = bounds.width;
    s.height = bounds.height;
    atlas.addSprite(s);
    var e = new SpriteEdit(this, s, scene.s2d);
    sprites[s] = e;
    var oldFocus = current;
    focus(s, true);
    
    undo.change(Custom( function(undo) {
      if (undo) {
        focus(oldFocus, true);
        atlas.removeSprite(s);
        sprites.remove(s);
        e.remove();
      } else {
        atlas.addSprite(s);
        sprites[s] = e;
        scene.s2d.addChild(e);
        focus(s, true);
        e.resync(true);
      }
    }));
  }
  
  public function clone(sprite:AtlasSprite, ev:Event) {
    var s = sprite.clone();
    storeEditorData(s);
    atlas.addSprite(s);
    var e = new SpriteEdit(this, s, scene.s2d);
    sprites[s] = e;
    var oldFocus = current;
    focus(s, true);
    
    undoChain = true;
    @:privateAccess e.drag.start(ev, @:privateAccess sprites[oldFocus].drag.inter);
    
    undo.change(Custom( function(undo) {
      if (undo) {
        focus(oldFocus, true);
        atlas.removeSprite(s);
        sprites.remove(s);
        e.remove();
      } else {
        atlas.addSprite(s);
        sprites[s] = e;
        scene.s2d.addChild(e);
        focus(s, true);
        this.undo.redo(); // Ensure it's moved
      }
    }));
  }
  
  public function delete(s:AtlasSprite) {
    var idx = s.index; trace("DEL");
    var e = sprites[s];
    focus(null, true);
    atlas.removeSprite(s);
    sprites.remove(s);
    e.remove();
    
    undo.change(Custom( function(undo) {
      if (undo) {
        atlas.addSprite(s, idx);
        sprites[s] = e;
        scene.s2d.addChild(e);
        focus(s, true);
      } else {
        focus(null, true);
        atlas.removeSprite(s);
        sprites.remove(s);
        e.remove();
      }
    }));
  }
  
  public function focus(sprite:AtlasSprite, isHistory:Bool = false):Void {
    if (current != null) sprites[current].focused = false;
    var old = current;
    current = sprite;
    storeEditorData(sprite);
    if (sprite != null) {
      sprites[sprite].focused = true;
      scene.s2d.over(sprites[sprite]);
    }
    
    initProps();
    if (!isHistory) {
      undo.change(Custom( function(undo) {
        if (undo) {
          focus(old, true);
        } else {
          focus(sprite, true);
        }
      }));
    }
  }
  
  function onAtlasChange(field:String) {
    switch (field) {
      case "texturePath": initTexture();
      case "_curr": focus(atlas.sprites[untyped atlas._curr]);
      case "_anim": focus(atlas.anims[untyped atlas._anim].sprites[0]);
    }
  }
  
  function onSpriteChange(field:String) {
    if (current != null) {
      trace(props.isTempChange);
      if (field == "current._id" && !props.isTempChange) {
        atlas.renameSprite(current, untyped current._id);
        initProps();
        return;
      } else if (field == "anim._id" && !props.isTempChange) {
        try { 
          atlas.renameAnim(anim, untyped anim._id);
        } catch (e:String) { }
        storeEditorData(current);
        initProps();
        return;
      } else {
        updateTexture(current, props.element.find('[data-index="${current.index}"]'));
      }
      sprites[current].resync(true);
    }
  }
  
  function onManageChange(field:String) {
    switch (field) {
      case "backgroundColor":
        scene.engine.backgroundColor = 0xff000000 | manageCtx.backgroundColor;
      case "checker":
        grid.visible = manageCtx.checker;
      case "whiteChecker":
        if (manageCtx.whiteChecker) {
          gridShader.whiteColor.setColor(0xffffffff);
          gridShader.blackColor.setColor(0xffcccccc);
        } else {
          gridShader.whiteColor.setColor(0xff333333);
          gridShader.blackColor.setColor(0xff111111);
        }
      case "checkerSize":
        gridShader.checkerSize = manageCtx.checkerSize;
    }
  }
  
  public function resyncSprite() {
    if (current != null) {
      var a = current;
      props.element.find("[field='current.x']").val(a.x).next().val(a.x);
      props.element.find("[field='current.y']").val(a.y).next().val(a.y);
      props.element.find("[field='current.width']").val(a.width).next().val(a.width);
      props.element.find("[field='current.height']").val(a.height).next().val(a.height);
      var base = props.element.find('[data-index="${a.index}"]');
      updateTexture(a, base);
      base.next().find(">span").text('#${a.index} @ [${a.x},${a.y}; ${a.width}x${a.height}]');
    }
  }
  
  public function sizeUndo(s:AtlasSprite, b:IBounds) {
    var cur = IBounds.fromValues(s.x, s.y, s.width, s.height);
    var isChain = undoChain;
    undoChain = false;
    undo.change(Custom( function(undo) {
      if (undo) {
        s.x = b.x;
        s.y = b.y;
        s.width = b.width;
        s.height = b.height;
      } else {
        s.x = cur.x;
        s.y = cur.y;
        s.width = cur.width;
        s.height = cur.height;
      }
      resyncSprite();
      sprites[s].resync(true);
      if (undo && isChain) this.undo.undo();
    }));
  }
  
  function updateTexture(sprite:AtlasSprite, el:Element) {
    var tex = el.find(".tile-preview");
    var scale = Math.min(80 / sprite.width, 60 / sprite.height);
    var size = atlas.texture.width * scale;
    tex.css({
      'background-size': size + "px",
      'background-position': (-sprite.x * scale) + "px " + (-sprite.y * scale) + "px",
      width: sprite.width * scale + "px",
      height: sprite.height * scale + "px"
    });
    tex.toggleClass("mag", scale >= 1);
    return tex;
  }
  
  function initProps() {
    
    props.clear();
    if (current != null) {
      untyped atlas._curr = atlas.sprites.indexOf(current);
      untyped atlas._anim = current.id;
    } else {
      untyped atlas._curr = null;
      untyped atlas._anim = null;
    }
    
    props.add(PropsEditor.makeSectionEl("General", new Element('<dl>
      <dt>Texture</dt><dd><input type="texturepath" field="texturePath"></dd>
      <dt>Anim</dt><dd><select field="_anim" type="text">${[for(s in atlas.anims.keys()) '<option value="$s">$s</option>'].join("")}</select></dd>
      <dt>Sprite</dt><dd><select field="_curr" type="number">${[for(i in 0...atlas.sprites.length) '<option value="$i">${atlas.sprites[i].fid}</option>'].join("")}</select></dd>
    </dl>')), atlas, onAtlasChange);
    // props.add(PropsEditor.makeSectionEl("General", PropsEditor.makePropsList([
    //   { name: "texturePath", t: PTexture, disp: "Texture" },
    //   { name: "_curr", t: PChoice([for (s in atlas.sprites) s.fid]), disp: "Sprite" }
    // ])), atlas, onAtlasChange);
    
    var max = 1024;
    if (atlas.texture != null) max = atlas.texture.getTexture().width;
    var tp:Element;
    if (current != null) {
      tp = new Element('<dl>
        <dt>ID</dt><dd><input type="text" field="current._id"></dd>
        <dt>Position</dt><dd class="vec2">
          <span>X</span> <input type="number" max="$max" field="current.x"/>
          <span>Y</span> <input type="number" max="$max" field="current.y"/>
        </dd>
        <dt>Size</dt><dd class="vec2">
          <span>W</span> <input type="number" max="$max" field="current.width"/>
          <span>H</span> <input type="number" max="$max" field="current.height"/>
        </dd>
        <dt>Origin</dt><dd class="vec2">
          <span>X</span> <input type="number" max="$max" field="current.originX"/>
          <span>Y</span> <input type="number" max="$max" field="current.originY"/>
        </dd>
        <dt>Delay</dt><dd><input type="number" step="0.01" max="100" field="current.delay"></dd>
      </dl>');
      // tp = PropsEditor.makePropsList([
      //   { name: "current._id", t:PString(), disp: "ID" },
      //   { name: "current.x", t:PInt(0, max), disp: "X" },
      //   { name: "current.y", t:PInt(0, max), disp: "Y" },
      //   { name: "current.width", t:PInt(0, max), disp: "Width" },
      //   { name: "current.height", t:PInt(0, max), disp: "Height" },
      //   { name: "current._origin", t:PVec(2, -100, 100), disp: "Origin" },
      //   { name: "current.delay", t:PFloat(0, 100), disp: "Delay" },
      // ]);
      tp = PropsEditor.makeGroupEl("Tile info", tp);
      // tp.append(new Element("<div class='tile-preview'></div>")) // TODO
      var el = new Element("<dl class='anim-info'></dl>");
      var animInfo = atlas.anims.get(current.id);
      var anim = animInfo.sprites;
      for (a in anim) {
        var base = new Element('<dt data-index="${a.index}"><div class="tile-preview"></div></dt>
          <dd class="selectable">
            <input class="btn move-up" type="button" value="↑" title="Move up"/><input class="btn move-down" type="button" value="↓" title="Move down"/>
            <span class="info">#${a.index} @ [${a.x},${a.y}; ${a.width}x${a.height}]</span>
          </dd>');
        // TODO: Rename whole animation
        base.find(".move-up,.move-down").click(function(e) {
          var idx = Std.parseInt(e.getThis().parent().prev().attr("data-index"));
          var idx2 = e.getThis().hasClass("move-up") ? idx - 1 : idx + 1;
          if (idx2 >= 0 && idx2 < anim.length) {
            var tmp = anim[idx];
            anim[idx] = anim[idx2];
            anim[idx2] = tmp;
            anim[idx].index = idx;
            tmp.index = idx2;
            if (idx == 0) atlas.names[tmp.id] = anim[idx];
            else if (idx2 == 0) atlas.names[tmp.id] = anim[idx2];
            initProps();
          }
        });
        
        if (a == current) base.filter("dd").addClass("selected");
        
        var tex = base.find(".tile-preview");
        var foc = focus.bind(a);
        tex.click( function(_) { foc(); } );
        tex.css("background-image", "url('file://" + ide.getPath(atlas.texturePath) + "')");
        updateTexture(a, base);
        base.appendTo(el);
      }
      PropsEditor.makePropsList([{ name: "anim._id", t: PString(), disp: "Anim name"}]).children().appendTo(el);
      tp = tp.add(PropsEditor.makeGroupEl("Animation info", el));
    } else {
      tp = PropsEditor.makePropsList([{ name: "none", disp: "", t: PUnsupported("Select tile first!") }]);
    }
    props.add(PropsEditor.makeSectionEl("Selected sprite", tp), this, onSpriteChange);
    
    props.add(PropsEditor.makeSectionEl("Manage", PropsEditor.makePropsList([
      { name: "backgroundColor", t: PVec(3), disp: "BG Color" },
      { name: "checker", t: PBool, disp: "Show checker" },
      { name: "whiteChecker", t:PBool, disp: "White checker" },
      { name: "checkerSize", t:PInt(2, 64), disp: "Checker size" }
    ])), manageCtx, onManageChange);
    
  }
  
  override public function getDefaultContent():Bytes {
    return Bytes.ofString(Json.stringify(new AtlasData().save()));
  }
  
  override public function save() {
    sys.io.File.saveContent(getPath(), Json.stringify(atlas.save()));
    super.save();
  }
  
  static var _ = hide.view.FileTree.registerExtension(AtlasEditor, ["atl"], {
    icon: "image",
    createNew: "Atlas"
  });
  @:keep
  static var __ = (function() {
    var css = js.Browser.document.createStyleElement();
    css.textContent = cherry.macro.Helper.getContent("style.css");
    js.Browser.document.head.appendChild(css);
    return true;
  })();
  
}
