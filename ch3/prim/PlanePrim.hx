package ch3.prim;

import h3d.Engine;
import h3d.prim.Primitive;
import h3d.col.Bounds;
import hxd.FloatBuffer;

enum PlaneFront
{
  X;
  Y;
  Z;
}

class PlanePrim extends Primitive
{
  
  public var width(default, null):Float;
  public var height(default, null):Float;
  public var ox(default, null):Float;
  public var oy(default, null):Float;
  public var u0(default, null):Float;
  public var u1(default, null):Float;
  public var v0(default, null):Float;
  public var v1(default, null):Float;
  public var front(default, null):PlaneFront;
  
  var buf:FloatBuffer;
  var bounds:Bounds;
  
  public function new(w:Float, h:Float, ox:Float = 0, oy:Float = 0, u0:Float = 0, v0:Float = 0, u1:Float = 1, v1:Float = 1, front:PlaneFront = Z)
  {
    width = w;
    height = h;
    this.ox = ox;
    this.oy = oy;
    this.u0 = u0;
    this.v0 = v0;
    this.u1 = u1;
    this.v1 = v1;
    this.front = front;
    invalidate();
  }
  
  public function setOrigin(ox, oy)
  {
    if (ox != this.ox || oy != this.oy)
    {
      this.ox = ox;
      this.oy = oy;
      invalidate();
    }
  }
  
  public function setSize(width, height)
  {
    if (width != this.width || height != this.height)
    {
      this.width = width;
      this.height = height;
      invalidate();
    }
  }
  
  public function setUV(u0, v0, u1, v1)
  {
    if (u0 != this.u0 || u1 != this.u1 || v0 != this.v0 || v1 != this.v1)
    {
      this.u0 = u0;
      this.v0 = v0;
      this.u1 = u1;
      this.v1 = v1;
      invalidate();
    }
  }
  
  public function setSizeUV(width, height, u0, v0, u1, v1)
  {
    if (width != this.width || height != this.height || u0 != this.u0 || u1 != this.u1 || v0 != this.v0 || v1 != this.v1)
    {
      this.width = width;
      this.height = height;
      this.u0 = u0;
      this.v0 = v0;
      this.u1 = u1;
      this.v1 = v1;
      invalidate();
    }
  }
  
  public function set(width, height, u0, v0, u1, v1, ox, oy)
  {
    this.width = width;
    this.height = height;
    this.u0 = u0;
    this.v0 = v0;
    this.u1 = u1;
    this.v1 = v1;
    this.ox = ox;
    this.oy = oy;
    invalidate();
  }
  
  public function setFront(front:PlaneFront)
  {
    this.front = front;
    invalidate();
  }
  
  function invalidate()
  {
    var cx = ox;
    var cy = oy;
    bounds = new Bounds();
    switch (front)
    {
      case X:
        bounds.yMin = -cx - width;
        bounds.zMin = -cy - height;
        bounds.yMax = bounds.yMin + width;
        bounds.zMax = bounds.zMin + height;
      case Y:
        bounds.xMin = -cx;
        bounds.zMin = -cy;
        bounds.xMax = bounds.xMin + width;
        bounds.zMax = bounds.zMin + height;
      case Z:
        bounds.xMin = cx;
        bounds.yMin = cy;
        bounds.xMax = width + cx;
        bounds.yMax = height + cy;
    }
    if (buf != null)
    {
      refill();
      buffer.uploadVector(buf, 0, 4);
    }
  }
  
  override function triCount()
  {
      return 2;
  }

  override function vertexCount()
  {
    return 4;
  }
  
  override public function alloc(engine:Engine)
  {
    buf = new FloatBuffer(8 * 4);
    refill();
    buffer = h3d.Buffer.ofFloats(buf, 8, [Quads]);
  }

  function refill():Void
  {
    var v = buf;
    var x0, y0, x1, y1;
    var nx = 0, ny = 0, nz = 0;
    
    var i = 0;
    
    inline function pt(x, y, z, _u, _v)
    {
      v[i++] = (  x); // x
      v[i++] = (  y); // y
      v[i++] = (  z); // z
      v[i++] = (  nx); // nx
      v[i++] = (  ny); // ny
      v[i++] = (  nz); // nz
      v[i++] = (  _u); // U
      v[i++] = (  _v); // V
    }
    
    switch (front)
    {
      case X:
        nx = 1;
        x0 = -ox - width;
        y0 = -oy - height;
        x1 = x0 + width;
        y1 = y0 + height;
        pt(0, x0, y0, u1, v1);
        pt(0, x1, y0, u0, v1);
        pt(0, x0, y1, u1, v0);
        pt(0, x1, y1, u0, v0);
      case Y:
        ny = 1;
        x0 = -ox - width;
        y0 = -oy - height;
        x1 = x0 + width;
        y1 = y0 + height;
        pt(x1, 0, y0, u1, v1);
        pt(x0, 0, y0, u0, v1);
        pt(x1, 0, y1, u1, v0);
        pt(x0, 0, y1, u0, v0);
      case Z:
        nz = 1;
        x0 = ox;
        y0 = oy;
        x1 = width + ox;
        y1 = height + oy;
        pt(x0, y0, 0, u0, v0);
        pt(x1, y0, 0, u1, v0);
        pt(x0, y1, 0, u0, v1);
        pt(x1, y1, 0, u1, v1);
    }
  }
  
  override function render(engine:h3d.Engine) {
    if( buffer == null || buffer.isDisposed() ) alloc(engine);
    engine.renderQuadBuffer(buffer);
  }
  
  override public function getBounds():Bounds
  {
    var b = new h3d.col.Bounds();
    b.add(bounds);
    return b;
  }
  
}