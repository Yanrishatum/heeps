package ch2;

import ch3.shader.MultiTexture2;
import h2d.Object;
import h3d.mat.Texture;
import ch3.shader.MultiTexture;
import h2d.RenderContext;
import h2d.Drawable;
import h2d.Tile;
import ch2.impl.BatchDrawStateExt;
import h2d.impl.BatchDrawState;

@:access(h2d.Tile)
private class BatchDrawerContent extends h3d.prim.Primitive {
  public static inline final stride:Int = 9;

  public var tmp:hxd.FloatBuffer;

  public var xMin:Float;
  public var yMin:Float;
  public var xMax:Float;
  public var yMax:Float;
  
  var state:BatchDrawStateExt;

  public var dirty:Bool;

  public function new() {
    state = new BatchDrawStateExt();
    clear();
  }

  public function clear() {
    tmp = new hxd.FloatBuffer();
    if (buffer != null)
      buffer.dispose();
    buffer = null;
    state.clear();
    xMin = hxd.Math.POSITIVE_INFINITY;
    yMin = hxd.Math.POSITIVE_INFINITY;
    xMax = hxd.Math.NEGATIVE_INFINITY;
    yMax = hxd.Math.NEGATIVE_INFINITY;
  }

  public function isEmpty() {
    return triCount() == 0;
  }

  override public function triCount() {
    return if (buffer == null) Std.int(tmp.length / stride) >> 1 else buffer.totalVertices() >> 1;
  }

  public inline function addColor(x:Float, y:Float, color:h3d.Vector, t:Tile) {
    add(x, y, color.r, color.g, color.b, color.a, t);
  }

  inline function getIndex(t:Tile) {
    return state.setTile(t);
    // state.setTile(t);
    // return 0;
  }

  public function add(x:Float, y:Float, r:Float, g:Float, b:Float, a:Float, t:Tile) {
    var sx = x + t.dx;
    var sy = y + t.dy;
    var index = getIndex(t);
    state.add(4);
    
    inline function color() {
      tmp.push(r);
      tmp.push(g);
      tmp.push(b);
      tmp.push(a);
      tmp.push(index);
    }
    tmp.push(sx);
    tmp.push(sy);
    tmp.push(t.u);
    tmp.push(t.v);
    color();
    tmp.push(sx + t.width);
    tmp.push(sy);
    tmp.push(t.u2);
    tmp.push(t.v);
    color();
    tmp.push(sx);
    tmp.push(sy + t.height);
    tmp.push(t.u);
    tmp.push(t.v2);
    color();
    tmp.push(sx + t.width);
    tmp.push(sy + t.height);
    tmp.push(t.u2);
    tmp.push(t.v2);
    color();

    var x = x + t.dx, y = y + t.dy;
    if (x < xMin)
      xMin = x;
    if (y < yMin)
      yMin = y;
    x += t.width;
    y += t.height;
    if (x > xMax)
      xMax = x;
    if (y > yMax)
      yMax = y;

    dirty = true;
  }

  public function addTransform(x:Float, y:Float, sx:Float, sy:Float, r:Float, c:h3d.Vector, t:Tile) {
    var ca = Math.cos(r), sa = Math.sin(r);
    var hx = t.width, hy = t.height;

    var index = getIndex(t);
    state.add(4);
    
    inline function color() {
      tmp.push(c.r);
      tmp.push(c.g);
      tmp.push(c.b);
      tmp.push(c.a);
      tmp.push(index);
    }

    inline function updateBounds(x, y) {
      if (x < xMin)
        xMin = x;
      if (y < yMin)
        yMin = y;
      if (x > xMax)
        xMax = x;
      if (y > yMax)
        yMax = y;
    }

    var dx = t.dx * sx, dy = t.dy * sy;
    var px = dx * ca - dy * sa + x;
    var py = dy * ca + dx * sa + y;

    tmp.push(px);
    tmp.push(py);
    tmp.push(t.u);
    tmp.push(t.v);
    color();
    updateBounds(px, py);

    var dx = (t.dx + hx) * sx, dy = t.dy * sy;
    var px = dx * ca - dy * sa + x;
    var py = dy * ca + dx * sa + y;

    tmp.push(px);
    tmp.push(py);
    tmp.push(t.u2);
    tmp.push(t.v);
    color();
    updateBounds(px, py);

    var dx = t.dx * sx, dy = (t.dy + hy) * sy;
    var px = dx * ca - dy * sa + x;
    var py = dy * ca + dx * sa + y;

    tmp.push(px);
    tmp.push(py);
    tmp.push(t.u);
    tmp.push(t.v2);
    color();
    updateBounds(px, py);

    var dx = (t.dx + hx) * sx, dy = (t.dy + hy) * sy;
    var px = dx * ca - dy * sa + x;
    var py = dy * ca + dx * sa + y;

    tmp.push(px);
    tmp.push(py);
    tmp.push(t.u2);
    tmp.push(t.v2);
    color();
    updateBounds(px, py);
    
    dirty = true;
  }

  public function recalcBounds() {
    xMin = hxd.Math.POSITIVE_INFINITY;
    yMin = hxd.Math.POSITIVE_INFINITY;
    xMax = hxd.Math.NEGATIVE_INFINITY;
    yMax = hxd.Math.NEGATIVE_INFINITY;
    var i = 0;
    final len = tmp.length;
    while (i < len) {
      var v = tmp[i];
      if (xMin > v) xMin = v;
      if (xMax < v) xMax = v;
      v = tmp[i];
      if (yMin > v) yMin = v;
      if (yMax < v) yMax = v;
      i += stride;
    }
  }

  public function addPoint(x:Float, y:Float, u:Float, v:Float, color:Int, index:Int) {
    tmp.push(x);
    tmp.push(y);
    tmp.push(u);
    tmp.push(v);
    insertColor(color, index);
    if (x < xMin)
      xMin = x;
    if (y < yMin)
      yMin = y;
    if (x > xMax)
      xMax = x;
    if (y > yMax)
      yMax = y;
    
    state.add(1);
  }

  inline function insertColor(c:Int, index:Int) {
    tmp.push(((c >> 16) & 0xFF) / 255.);
    tmp.push(((c >> 8) & 0xFF) / 255.);
    tmp.push((c & 0xFF) / 255.);
    tmp.push((c >>> 24) / 255.);
    tmp.push(index);
  }

  override public function alloc(engine:h3d.Engine) {
    if (tmp == null)
      clear();
    if (tmp.length > 0)
      buffer = h3d.Buffer.ofFloats(tmp, stride, [Quads, RawFormat]);
    dirty = false;
  }

  public inline function flush() {
    if (buffer == null || buffer.isDisposed())
      alloc(h3d.Engine.getCurrent());
    else if (dirty) {
      var nvert = Std.int(tmp.length / stride);
      if (buffer.vertices < nvert)
        alloc(h3d.Engine.getCurrent());
      else {
        buffer.uploadVector(tmp, 0, nvert);
        dirty = false;
      }
    }
  }

  public function doRender(ctx:RenderContext, shader, min, len) {
    flush();
    if (buffer != null)
      state.drawQuads(ctx, shader, buffer, min, len);
      // state.drawQuads(ctx, buffer, min, len);
  }
}

/**
  Experimental batched renderer with ability to modify state post-addition.
**/
class BatchDrawer extends Drawable {
  
  var content:BatchDrawerContent;
  var shader:MultiTexture2;
  var stateCount:Int = 0;
  var curColor : h3d.Vector;
  public var counter(default, null):Int;
  
  public function new(?parent) {
    super(parent);
    shader = new MultiTexture2();
    this.content = new BatchDrawerContent();
    addShader(shader);
    stateCount = 0;
    curColor = new h3d.Vector(1, 1, 1, 1);
  }
  
  public inline function invalidateBounds() {
    content.recalcBounds();
  }
  
  override function getBoundsRec( relativeTo : Object, out : h2d.col.Bounds, forSize : Bool ) {
    super.getBoundsRec(relativeTo, out, forSize);
    addBounds(relativeTo, out, content.xMin, content.yMin, content.xMax - content.xMin, content.yMax - content.yMin);
  }
  
  public function clear() {
    stateCount = 0;
    content.clear();
  }
  
  override function onRemove() {
    content.dispose();
    super.onRemove();
  }
  
  public static inline function getContentStride() return BatchDrawerContent.stride;
  
  public inline function getStride() {
    return BatchDrawerContent.stride;
  }
  
  public inline function getBuffer(forEdit:Bool = true) {
    if (forEdit) content.dirty = true;
    return content.tmp;
  }
  
  public function setDefaultColor( rgb : Int, alpha = 1.0 ) {
    curColor.x = ((rgb >> 16) & 0xFF) / 255;
    curColor.y = ((rgb >> 8) & 0xFF) / 255;
    curColor.z = (rgb & 0xFF) / 255;
    curColor.w = alpha;
  }
  
  public inline function add(x : Float, y : Float, t : h2d.Tile):Int {
    content.add(x, y, curColor.x, curColor.y, curColor.z, curColor.w, t);
    return counter++;
  }

  public inline function addColor( x : Float, y : Float, r : Float, g : Float, b : Float, a : Float, t : Tile):Int {
    content.add(x, y, r, g, b, a, t);
    return counter++;
  }

  public inline function addAlpha(x : Float, y : Float, a : Float, t : h2d.Tile):Int {
    content.add(x, y, curColor.x, curColor.y, curColor.z, a, t);
    return counter++;
  }

  public inline function addTransform(x : Float, y : Float, sx : Float, sy : Float, r : Float, t : Tile):Int {
    content.addTransform(x, y, sx, sy, r, curColor, t);
    return counter++;
  }
  
  public function setPos(index:Int, x:Float, y:Float) {
    if (index < 0 || index >= counter) return;
    final stride = BatchDrawerContent.stride;
    var offset = index * stride * 4;
    var tmp = content.tmp;
    var dx = x - tmp[offset];
    var dy = y - tmp[offset + 1];
    tmp[offset                 ] += dx;
    tmp[offset              + 1] += dy;
    tmp[offset + stride        ] += dx;
    tmp[offset + stride     + 1] += dy;
    tmp[offset + stride * 2    ] += dx;
    tmp[offset + stride * 2 + 1] += dy;
    tmp[offset + stride * 3    ] += dx;
    tmp[offset + stride * 3 + 1] += dy;
    content.dirty = true;
  }
  
  public function setUV(index:Int, u0:Float, v0:Float, u1:Float, v1:Float) {
    if (index < 0 || index >= counter) return;
    final stride = BatchDrawerContent.stride;
    var offset = index * stride * 4 + 2;
    var tmp = content.tmp;
    tmp[offset                 ] = u0;
    tmp[offset              + 1] = v0;
    tmp[offset + stride        ] = u1;
    tmp[offset + stride     + 1] = v0;
    tmp[offset + stride * 2    ] = u0;
    tmp[offset + stride * 2 + 1] = v1;
    tmp[offset + stride * 3    ] = u1;
    tmp[offset + stride * 3 + 1] = v1;
    content.dirty = true;
  }
  
  public inline function setTileUV(index:Int, tile:Tile) {
    @:privateAccess setUV(index, tile.u, tile.v, tile.u2, tile.v2);
  }
  
  public function setPosUV(index:Int, x:Float, y:Float, u0:Float, v0:Float, u1:Float, v1:Float) {
    if (index < 0 || index >= counter) return;
    final stride = BatchDrawerContent.stride;
    var offset = index * stride * 4;
    var tmp = content.tmp;
    var dx = x - tmp[offset];
    var dy = y - tmp[offset + 1];
    tmp[offset                 ] += dx;
    tmp[offset              + 1] += dy;
    tmp[offset              + 2]  = u0;
    tmp[offset              + 3]  = v0;
    tmp[offset + stride        ] += dx;
    tmp[offset + stride     + 1] += dy;
    tmp[offset + stride     + 2]  = u1;
    tmp[offset + stride     + 3]  = v0;
    tmp[offset + stride * 2    ] += dx;
    tmp[offset + stride * 2 + 1] += dy;
    tmp[offset + stride * 2 + 2]  = u0;
    tmp[offset + stride * 2 + 3]  = v1;
    tmp[offset + stride * 3    ] += dx;
    tmp[offset + stride * 3 + 1] += dy;
    tmp[offset + stride * 3 + 2]  = u1;
    tmp[offset + stride * 3 + 3]  = v1;
    content.dirty = true;
  }
  
  public function setPosTileUV(index, x:Float, y:Float, tile:Tile) {
    @:privateAccess setPosUV(index, x, y, tile.u, tile.v, tile.u2, tile.v2);
  }
  
  public function setColor(index:Int, r:Float, g:Float, b:Float, a:Float) {
    if (index < 0 || index >= counter) return;
    final stride = BatchDrawerContent.stride;
    var offset = index * stride * 4 + 4;
    var tmp = content.tmp;
    inline function setCol(o) {
      tmp[offset + stride * o    ] = r;
      tmp[offset + stride * o + 1] = g;
      tmp[offset + stride * o + 2] = b;
      tmp[offset + stride * o + 3] = a;
    }
    setCol(0);
    setCol(1);
    setCol(2);
    setCol(3);
    content.dirty = true;
  }
  
  public inline function setAlpha(index:Int, a:Float) {
    if (index < 0 || index >= counter) return;
    setIndexValue(index, a, 7);
    content.dirty = true;
  }
  
  function setIndexValue(index:Int, val:Float, offset:Int) {
    final offset = index * BatchDrawerContent.stride * 4 + offset;
    final tmp = content.tmp;
    tmp[offset             ] = val;
    tmp[offset + BatchDrawerContent.stride    ] = val;
    tmp[offset + BatchDrawerContent.stride * 2] = val;
    tmp[offset + BatchDrawerContent.stride * 3] = val;
  }
  
  public function drawWidth(obj:Drawable, shader:MultiTexture2, ctx:RenderContext) {
    ctx.beginDrawBatchState(obj);
    content.doRender(ctx, shader, 0, -1);
  }
  
  override function draw(ctx:RenderContext) {
    ctx.beginDrawBatchState(this);
    content.doRender(ctx, shader, 0, -1);
  }

  override function sync( ctx : RenderContext ) {
    super.sync(ctx);
    content.flush();
  }
}
