package ch2;

import h2d.Object;
import h3d.mat.Texture;
import ch3.shader.MultiTexture;
import h2d.RenderContext;
import h2d.Drawable;
import h2d.Tile;

@:access(h2d.Tile)
private class BatchDrawerContent extends h3d.prim.Primitive {
  public static inline final stride:Int = 9;

  public var tmp:hxd.FloatBuffer;

  public var xMin:Float;
  public var yMin:Float;
  public var xMax:Float;
  public var yMax:Float;

  public var dirty:Bool;

  public function new() {
    clear();
  }

  public function clear() {
    tmp = new hxd.FloatBuffer();
    if (buffer != null)
      buffer.dispose();
    buffer = null;
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

  public inline function addColor(x:Float, y:Float, color:h3d.Vector, t:Tile, index:Int) {
    add(x, y, color.r, color.g, color.b, color.a, t, index);
  }

  public function add(x:Float, y:Float, r:Float, g:Float, b:Float, a:Float, t:Tile, index:Int) {
    var sx = x + t.dx;
    var sy = y + t.dy;
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

  public function addTransform(x:Float, y:Float, sx:Float, sy:Float, r:Float, c:h3d.Vector, t:Tile, index:Int) {
    var ca = Math.cos(r), sa = Math.sin(r);
    var hx = t.width, hy = t.height;

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

  public function doRender(engine:h3d.Engine, min, len) {
    flush();
    if (buffer != null)
      engine.renderQuadBuffer(buffer, min, len);
  }
}

/**
  Experimental batched renderer with ability to modify state post-addition.
**/
class BatchDrawer extends Drawable {
  
  var content:BatchDrawerContent;
  var textureShader:MultiTexture;
  var states:Array<BatchState>;
  var stateCount:Int = 0;
  var curColor : h3d.Vector;
  var counter:Int;
  
  public function new(?parent) {
    super(parent);
    this.content = new BatchDrawerContent();
    this.states = [new BatchState(this, 0)];
    textureShader = new MultiTexture();
    this.addShader(textureShader);
    stateCount = 0;
    curColor = new h3d.Vector(1, 1, 1, 1);
  }
  
  override function getBoundsRec( relativeTo : Object, out : h2d.col.Bounds, forSize : Bool ) {
    super.getBoundsRec(relativeTo, out, forSize);
    addBounds(relativeTo, out, content.xMin, content.yMin, content.xMax - content.xMin, content.yMax - content.yMin);
  }
  
  public function clear() {
    stateCount = 0;
    for (s in states) s.reset();
  }
  
  override function onRemove() {
    content.dispose();
    super.onRemove();
  }
  
  public function setDefaultColor( rgb : Int, alpha = 1.0 ) {
    curColor.x = ((rgb >> 16) & 0xFF) / 255;
    curColor.y = ((rgb >> 8) & 0xFF) / 255;
    curColor.z = (rgb & 0xFF) / 255;
    curColor.w = alpha;
  }
  
  public inline function add(x : Float, y : Float, t : h2d.Tile):Int {
    content.add(x, y, curColor.x, curColor.y, curColor.z, curColor.w, t, addRef(t));
    return counter++;
  }

  public inline function addColor( x : Float, y : Float, r : Float, g : Float, b : Float, a : Float, t : Tile):Int {
    content.add(x, y, r, g, b, a, t, addRef(t));
    return counter++;
  }

  public inline function addAlpha(x : Float, y : Float, a : Float, t : h2d.Tile):Int {
    content.add(x, y, curColor.x, curColor.y, curColor.z, a, t, addRef(t));
    return counter++;
  }

  public inline function addTransform(x : Float, y : Float, sx : Float, sy : Float, r : Float, t : Tile):Int {
    content.addTransform(x, y, sx, sy, r, curColor, t, addRef(t));
    return counter++;
  }
  
  public function setPos(index:Int, x:Float, y:Float) {
    if (index < 0 || index >= counter) return;
    final stride = BatchDrawerContent.stride;
    var offset = index * stride;
    var tmp = content.tmp;
    var dx = x - tmp[offset];
    var dy = y - tmp[offset];
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
    var offset = index * stride + 2;
    var tmp = content.tmp;
    tmp[offset                 ] = u0;
    tmp[offset              + 1] = v0;
    tmp[offset + stride        ] = u1;
    tmp[offset + stride     + 1] = v0;
    tmp[offset + stride * 2    ] = u1;
    tmp[offset + stride * 2 + 1] = v1;
    tmp[offset + stride * 3    ] = u0;
    tmp[offset + stride * 3 + 1] = v1;
    content.dirty = true;
  }
  
  public function setPosUV(index:Int, x:Float, y:Float, u0:Float, v0:Float, u1:Float, v1:Float) {
    if (index < 0 || index >= counter) return;
    final stride = BatchDrawerContent.stride;
    var offset = index * stride;
    var tmp = content.tmp;
    var dx = x - tmp[offset];
    var dy = y - tmp[offset];
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
    tmp[offset + stride * 2 + 2]  = u1;
    tmp[offset + stride * 2 + 3]  = v1;
    tmp[offset + stride * 3    ] += dx;
    tmp[offset + stride * 3 + 1] += dy;
    tmp[offset + stride * 3 + 2]  = u0;
    tmp[offset + stride * 3 + 3]  = v1;
    content.dirty = true;
  }
  
  public function setColor(index:Int, r:Float, g:Float, b:Float, a:Float) {
    if (index < 0 || index >= counter) return;
    final stride = BatchDrawerContent.stride;
    var offset = index * stride + 4;
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
  
  function addRef(t:Tile) {
    if (stateCount == 0) {
      stateCount++;
      return states[0].add(t);
    } else {
      var idx = states[stateCount - 1].add(t);
      if (idx == -1) {
        var state:BatchState;
        if (stateCount == states.length) {
          states.push(state = new BatchState(this, counter));
        } else {
          state = states[stateCount];
          state.start = counter;
        }
        state.add(t);
        stateCount++;
        return 0;
      }
      return idx;
    }
  }
  
  override function draw(ctx:RenderContext) {
    for (i in 0...stateCount) {
      states[i].draw(ctx, content);
    }
  }

  override function sync( ctx : RenderContext ) {
    super.sync(ctx);
    content.flush();
  }
}

@:access(ch2.BatchDrawer)
@:access(ch2.SpriteBatchExt)
class BatchState {
  var drawer:BatchDrawer;
  
  var textureIndex:Array<Texture>;
  var texture:Texture;
  var texture1:Texture;
  var texture2:Texture;
  var texture3:Texture;
  var texture4:Texture;
  var texture5:Texture;
  var texture6:Texture;
  var texture7:Texture;
  var allocTextures = 0;
  
  public var start:Int;
  public var count:Int;
  
  public function add(t:Tile):Int {
    var tex = t.getTexture();
    var idx = textureIndex.indexOf(tex);
    if (idx == -1)
    {
      if (allocTextures == 8) return -1;
      switch (allocTextures) {
        case 0: texture = tex;
        case 1: texture1 = tex;
        case 2: texture2 = tex;
        case 3: texture3 = tex;
        case 4: texture4 = tex;
        case 5: texture5 = tex;
        case 6: texture6 = tex;
        case 7: texture7 = tex;
      }
      allocTextures++;
    }
    count++;
    return idx;
  }
  
  public function new(drawer:BatchDrawer, offset:Int) {
    this.drawer = drawer;
    textureIndex = [];
    reset();
    this.start = offset;
  }
  
  public function reset() {
    start = 0;
    count = 0;
    textureIndex = [];
    allocTextures = 0;
    texture = MultiTexture.noTexture;
    texture1 = MultiTexture.noTexture;
    texture2 = MultiTexture.noTexture;
    texture3 = MultiTexture.noTexture;
    texture4 = MultiTexture.noTexture;
    texture5 = MultiTexture.noTexture;
    texture6 = MultiTexture.noTexture;
    texture7 = MultiTexture.noTexture;
  }
  
  public function draw(ctx:RenderContext, content:BatchDrawerContent) {
    if (!ctx.beginDrawObject(drawer, texture)) return;
    var shader = drawer.textureShader;
    shader.texture1 = texture1;
    shader.texture2 = texture2;
    shader.texture3 = texture3;
    shader.texture4 = texture4;
    shader.texture5 = texture5;
    shader.texture6 = texture6;
    shader.texture7 = texture7;
    content.doRender(ctx.engine, start*2, count*2);
  }
  
}
