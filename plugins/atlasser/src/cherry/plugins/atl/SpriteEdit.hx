package cherry.plugins.atl;

import hxd.Key;
import h2d.RenderContext;
import cherry.plugins.generic.shaders.OutlineShader;
import h2d.Interactive;
import h2d.col.Bounds;
import h2d.col.Point;
import h2d.col.IBounds;
import h2d.Graphics;
import h2d.Text;
import cherry.fmt.atl.Data;
import h2d.Object;
import cherry.plugins.atl.States;

class SpriteEdit extends Object {
  
  public var ed:AtlasEditor;
  public var sprite:AtlasSprite;
  var g:Graphics;
  var label:Text;
  var drag:CornerEdit;
  var topLeft:CornerEdit;
  var topRight:CornerEdit;
  var bottomLeft:CornerEdit;
  var bottomRight:CornerEdit;
  var top:CornerEdit;
  var right:CornerEdit;
  var bottom:CornerEdit;
  var left:CornerEdit;
  final corners:Array<CornerEdit>;
  
  var old:IBounds;
  var dragCorner:Point;
  var b:Bounds;
  var ib:IBounds;
  
  var focusInter:Interactive;
  
  public var focused(default, set):Bool;
  
  function set_focused(v) {
    this.focused = v;
    resync(true);
    return v;
  }
  
  public function new(ed:AtlasEditor, s:AtlasSprite, parent:Object) {
    super(parent);
    this.ed = ed;
    this.sprite = s;
    g = new Graphics(this);
    var out = new OutlineShader();
    g.addShader(out);
    label = new Text(hxd.res.DefaultFont.get(), this);
    label.dropShadow = { dx: 1, dy: 1, alpha: 1, color: 0 };
    drag = new CornerEdit(sprite.width, sprite.height, Center, this);
    topLeft = new CornerEdit(TopLeft, this);
    topRight = new CornerEdit(TopRight, this);
    bottomLeft = new CornerEdit(BottomLeft, this);
    bottomRight = new CornerEdit(BottomRight, this);
    top = new CornerEdit(4, 4, Top, this);
    right = new CornerEdit(4, 4, Right, this);
    bottom = new CornerEdit(4, 4, Bottom, this);
    left = new CornerEdit(4, 4, Left, this);
    corners = [topLeft, topRight, bottomLeft, bottomRight, top, right, bottom, left];
    
    focusInter = new Interactive(sprite.width, sprite.height, this);
    focusInter.onWheel = (e) -> e.propagate = true;
    focusInter.onClick = (e) -> e.button == 0 ? ed.focus(sprite) : e.propagate = true;
    focusInter.enableRightButton = true;
    
    b = new Bounds();
    dragCorner = new Point();
    
    // topLeft.maxScale = topRight.maxScale = bottomLeft.maxScale = bottomRight.maxScale = 4;
    // top.maxScale = right.maxScale = bottom.maxScale = left.maxScale = 2;
    
    resync(true);
    
    drag.onChangeT = dragCenter;
    drag.onStartT = dragStart;
    
    for (c in corners) {
      c.onStartT = dragStart;
      c.onChangeT = dragResize;
      c.maxScale = 4;
    }
  }
  
  inline function clampW(v:Float) return hxd.Math.clamp(v, 0, ed.tex.tile.width);
  inline function clampH(v:Float) return hxd.Math.clamp(v, 0, ed.tex.tile.height);
  
  override function sync(ctx:RenderContext)
  {
    label.visible = Key.isDown(Key.ALT);
    super.sync(ctx);
  }
  
  function dragStart(type:CornerType) {
    old = IBounds.fromValues(sprite.x, sprite.y, sprite.width, sprite.height);
    var anch = new Point(sprite.x + sprite.width*.5, sprite.y + sprite.height * .5);
    ed.tex.localToGlobal(anch);
    for (c in corners) if (c.type == type) {
      c.cardinalAnchor = anch;
      break;
    }
    if (type == Center) drag.cardinalAnchor = anch;
    switch(type) {
      case TopLeft: dragCorner.set(sprite.x + sprite.width, sprite.y + sprite.height);
      case TopRight: dragCorner.set(sprite.x, sprite.y + sprite.height);
      case BottomLeft: dragCorner.set(sprite.x + sprite.width, sprite.y);
      case BottomRight: dragCorner.set(sprite.x, sprite.y);
      case Top: dragCorner.set(sprite.x + sprite.width, sprite.y + sprite.height);
      case Bottom: dragCorner.set(sprite.x + sprite.width, sprite.y);
      case Left: dragCorner.set(sprite.x + sprite.width, sprite.y + sprite.height);
      case Right: dragCorner.set(sprite.x, sprite.y + sprite.height);
      case Center: // none
    }
  }
  
  function dragCenter(type:CornerType, done:Bool) {
    sprite.x = Math.floor(clampW(drag.pos.x));
    sprite.y = Math.floor(clampH(drag.pos.y));
    ed.resyncSprite();
    if (done) {
      resync(false);
      ed.sizeUndo(sprite, old);
    } else {
      redraw();
    }
  }
  
  function dragResize(type:CornerType,done:Bool) {
    b.empty();
    switch (type) {
      case TopLeft: b.addPoint(topLeft.pos);
      case TopRight: b.addPoint(topRight.pos);
      case BottomLeft: b.addPoint(bottomLeft.pos);
      case BottomRight: b.addPoint(bottomRight.pos);
      case Top: b.addPos(sprite.x, top.pos.y);
      case Right: b.addPos(right.pos.x, sprite.y);
      case Bottom: b.addPos(sprite.x, bottom.pos.y);
      case Left: b.addPos(left.pos.x, sprite.y);
      case Center: // nothing
    }
    b.addPoint(dragCorner);
    ib = b.toIBounds();
    sprite.x = ib.x;
    sprite.y = ib.y;
    sprite.width = ib.width;
    sprite.height = ib.height;
    ed.resyncSprite();
    if (Key.isDown(Key.SHIFT)) {
      // TODO: 45-degree snap
    }
    if (done) {
      drag.width = sprite.width;
      drag.height = sprite.height;
      resync(true);
      ed.sizeUndo(sprite, old);
    } else {
      redraw();
    }
  }
  
  function redraw() {
    var s = ed.currZoom;
    var pt = new Point(sprite.x, sprite.y);
    localToLocal(pt, ed.tex);
    label.x = pt.x;
    label.y = pt.y;
    g.clear();
    g.lineStyle(1, focused ? 0xff0000 : 0xcccccc);
    g.beginFill(0, 0);
    g.drawRect(pt.x-0.5, pt.y-0.5, sprite.width * s+1, sprite.height * s+1);
    g.endFill();
    if (focused) {
      var ms = Math.max(1, Math.min(s, topLeft.maxScale));
      var w = topLeft.width; var h = topLeft.height;
      inline function ctrl(x:Float, y:Float) {
        g.drawRect(pt.x + x * s - w * .5 * ms, pt.y + y * s - h * .5 * ms, w * ms, h * ms);
      }
      g.lineStyle(1, 0xeeeeee);
      g.beginFill(0x8c8c8c, 0.3);
      ctrl(0, 0);
      ctrl(sprite.width, 0);
      ctrl(0, sprite.height);
      ctrl(sprite.width, sprite.height);
      // ms = Math.min(s, 3);
      w = top.width; h = top.height;
      ctrl(sprite.width * .5, 0);
      ctrl(sprite.width * .5, sprite.height);
      ctrl(0, sprite.height * .5);
      ctrl(sprite.width, sprite.height * .5);
    }
    
  }
  
  function localToLocal(pt:Point, from:Object) {
    from.localToGlobal(pt);
    globalToLocal(pt);
  }
  
  public function resync(resized:Bool) {
    var s = ed.currZoom;
    this.x = ed.tex.absX + sprite.x * s;
    this.y = ed.tex.absY + sprite.y * s;
    label.text = sprite.fid;
    redraw();
    focusInter.visible = !focused;
    if (resized) {
      focusInter.width = sprite.width * s;
      focusInter.height = sprite.height * s;
    }
    var v = focused;
    drag.visible = v;
    drag.resync(resized);
    for (c in corners) {
      c.visible = v;
      c.resync(resized);
    }
  }
  
}
