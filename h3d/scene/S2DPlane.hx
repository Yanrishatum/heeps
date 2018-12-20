package h3d.scene;

import hxd.FloatBuffer;
import h3d.col.Bounds;
import h3d.prim.Primitive;
import h3d.Buffer;
import h3d.scene.RenderContext;
import h3d.mat.Material;
import h3d.mat.Data;
import h3d.scene.Mesh;

class S2DPlane extends Mesh
{
  public var root:S2DPlaneRoot;
  public var immediateMode:Bool;
  
  private var _dirty:Bool;
  private var _bounds:h2d.col.Bounds;
  private var _autoresize:Bool;
  private var _texture:h3d.mat.Texture;
  private var _ppu:Float;
  private var _plane:DrawPrim;
  
  public var filter(get, set):Filter;
  public var ppu(get, set):Float;
  
  private inline function get_ppu():Float { return _ppu; }
  private inline function set_ppu(v:Float):Float
  {
    _dirty = true;
    _plane.ppu = v;
    _plane.invalid = true;
    return _ppu = v;
  }
  
  private inline function get_filter():Filter { return _texture.filter; }
  private inline function set_filter(v:Filter):Filter
  {
    _dirty = true;
    return _texture.filter = v;
  }
  
  public function new(parent:h3d.scene.Object, immediateMode:Bool = false, textureWidth:Int = 512, textureHeight:Int = 512, ppu:Float = 1, autoresize:Bool = false)
  {
    root = new S2DPlaneRoot(this);
    this.immediateMode = immediateMode;
    _bounds = new h2d.col.Bounds();
    // _autoresize = autoresize; // TODO
    _dirty = true;
    _ppu = ppu;
    
    // TODO: Optimize by using atlas.
    _texture = new h3d.mat.Texture(textureWidth, textureHeight, [TextureFlags.Target, TextureFlags.Dynamic]); 
    super(_plane = new DrawPrim(textureWidth, textureHeight, _texture.width, _texture.height, ppu), h3d.mat.Material.create(_texture), parent);
  }
  
  inline public function invalidate():Void { _dirty = true; }
  
  override private function sync(ctx:RenderContext)
  {
    super.sync(ctx);
    if (_dirty || immediateMode)
    {
      root.getBounds(null, _bounds);
      if (_autoresize)
      {
        if (_bounds.width > _texture.width || _bounds.height > _texture.height)
        {
          var newW = _texture.width;
          var newH = _texture.height;
          if (_bounds.width > _texture.width) newW <<= 1;
          if (_bounds.height > _texture.height) newH <<= 1;
          _texture.resize(newW, newH);
        }
      }
      _plane.resize(_bounds.width, _bounds.height, _texture.width, _texture.height);
      _texture.clear(0, 0);
      root.drawTo(_texture);
      _dirty = false;
    }
  }
  
  override public function dispose()
  {
    _texture.dispose();
    _texture = null;
    root.removeChildren();
    root.plane = null;
    root = null;
    super.dispose();
  }
  
}

@:access(h3d.scene.S2DPlane)
@:allow(h3d.scene.S2DPlane)
class S2DPlaneRoot extends h2d.Object
{
  
  private var plane:S2DPlane;
  
  function new(plane:S2DPlane)
  {
    super();
    this.plane = plane;
    parentContainer = this;
  }
  
  override private function contentChanged(s:h2d.Object)
  {
    this.plane._dirty = true;
  }
  
  override private function drawRec(ctx:h2d.RenderContext)
  {
    sync(ctx);
    super.drawRec(ctx);
  }
  
}

private class DrawPrim extends Primitive
{
  
  private var _b:Bounds;
  private var _w:Float;
  private var _h:Float;
  private var _tx:Int;
  private var _ty:Int;
  private var _buf:FloatBuffer;
  public var ppu:Float;
  public var invalid:Bool;
  
  public function new(w:Float, h:Float, tx:Int, ty:Int, ppu:Float)
  {
    this.ppu = ppu;
    resize(w, h, tx, ty);
  }
  
  public function resize(w:Float, h:Float, tx:Int, ty:Int):Void
  {
    if (_w == w && _h == h && !invalid) return;
    invalid = false;
    _w = w;
    _h = h;
    _tx = tx;
    _ty = ty;
    
    var hw:Float = (w/ppu)/2;
    var hh:Float = (w/ppu)/2;
    _b = new Bounds();
    _b.addPoint(new h3d.col.Point(-hw, -hh, 0));
    _b.addPoint(new h3d.col.Point( hw, -hh, 0));
    _b.addPoint(new h3d.col.Point(-hw,  hh, 0));
    _b.addPoint(new h3d.col.Point( hw,  hh, 0));
    if (_buf != null)
    {
      refill();
      buffer.uploadVector(_buf, 0, 4);
    }
  }
  
	override function triCount() {
		return 2;
	}

	override function vertexCount() {
		return 4;
	}

	override function alloc( engine : h3d.Engine ) {
		_buf = new hxd.FloatBuffer();
    
    refill();
    
		buffer = h3d.Buffer.ofFloats(_buf, 8, [Quads, Dynamic]);
	}
  
  inline function refill():Void
  {
    var v = _buf;
    var ww = (_w/ppu) / 2;
    var hh = (_h/ppu) / 2;
    var i = 0;
    
    var U = _w / _tx;
    var V = _h / _ty;
    // Top-left
    v[i++] = (  -ww); // x
    v[i++] = (  -hh); // y
    v[i++] = (   0); // z
    v[i++] = (   0); // nx
    v[i++] = (   0); // ny
    v[i++] = (   1); // nz
    v[i++] = (   0); // U
    v[i++] = (   0); // V
    
    // Top-right
    v[i++] = (   ww); // x
    v[i++] = (  -hh); // y
    v[i++] = (   0); // z
    v[i++] = (   0); // nx
    v[i++] = (   0); // ny
    v[i++] = (   1); // nz
    v[i++] = (   U); // U
    v[i++] = (   0); // V
    
    // Bottom-left
    v[i++] = (  -ww); // x
    v[i++] = (   hh); // y
    v[i++] = (   0); // z
    v[i++] = (   0); // nx
    v[i++] = (   0); // ny
    v[i++] = (   1); // nz
    v[i++] = (   0); // U
    v[i++] = (   V); // V
    
    // Bottom-right
    v[i++] = (   ww); // x
    v[i++] = (   hh); // y
    v[i++] = (   0); // z
    v[i++] = (   0); // nx
    v[i++] = (   0); // ny
    v[i++] = (   1); // nz
    v[i++] = (   U); // U
    v[i++] = (   V); // V
    
  }
  
	override function render(engine:h3d.Engine) {
		if( buffer == null || buffer.isDisposed() ) alloc(engine);
		engine.renderQuadBuffer(buffer);
	}
  
  override public function getBounds():Bounds
  {
		var b = new h3d.col.Bounds();
    b.add(_b);
		return b;
  }
  
}