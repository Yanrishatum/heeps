package h2d;

import h3d.shader.MultiTexture;
import h3d.mat.Texture;
import h2d.SpriteBatchExt.TextureRef;

// TileLayerContent is private class, hence can't really utilize it.
private class TileLayerContentExt extends h3d.prim.Primitive
{
  
	var tmp : hxd.FloatBuffer;
	public var xMin : Float;
	public var yMin : Float;
	public var xMax : Float;
	public var yMax : Float;

	public function new() {
		clear();
	}

	public function clear() {
		tmp = new hxd.FloatBuffer();
		if( buffer != null ) buffer.dispose();
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
		return if( buffer == null ) Std.int(tmp.length / 9) >> 1 else buffer.totalVertices() >> 1;
	}

	public inline function addColor( x : Float, y : Float, color : h3d.Vector, t : Tile, index:Int ) {
		add(x, y, color.r, color.g, color.b, color.a, t, index);
	}

	public function add( x : Float, y : Float, r : Float, g : Float, b : Float, a : Float, t : Tile, index:Int ) {
		var sx = x + t.dx;
		var sy = y + t.dy;
    inline function color()
    {
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
		if( x < xMin ) xMin = x;
		if( y < yMin ) yMin = y;
		x += t.width;
		y += t.height;
		if( x > xMax ) xMax = x;
		if( y > yMax ) yMax = y;
	}

	public function addTransform( x : Float, y : Float, sx : Float, sy : Float, r : Float, c : h3d.Vector, t : Tile, index:Int ) {

		var ca = Math.cos(r), sa = Math.sin(r);
		var hx = t.width, hy = t.height;

    inline function color()
    {
  		tmp.push(c.r);
  		tmp.push(c.g);
  		tmp.push(c.b);
  		tmp.push(c.a);
      tmp.push(index);
    }
    
		inline function updateBounds( x, y ) {
			if( x < xMin ) xMin = x;
			if( y < yMin ) yMin = y;
			if( x > xMax ) xMax = x;
			if( y > yMax ) yMax = y;
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
	}

	public function addPoint( x : Float, y : Float, color : Int ) {
		tmp.push(x);
		tmp.push(y);
		tmp.push(0);
		tmp.push(0);
		insertColor(color, 0);
		if( x < xMin ) xMin = x;
		if( y < yMin ) yMin = y;
		if( x > xMax ) xMax = x;
		if( y > yMax ) yMax = y;
	}

	inline function insertColor( c : Int, index :Int ) {
		tmp.push(((c >> 16) & 0xFF) / 255.);
		tmp.push(((c >> 8) & 0xFF) / 255.);
		tmp.push((c & 0xFF) / 255.);
		tmp.push((c >>> 24) / 255.);
    tmp.push(index);
	}

	public inline function rectColor( x : Float, y : Float, w : Float, h : Float, color : Int, index:Int = 0 ) {
		tmp.push(x);
		tmp.push(y);
		tmp.push(0);
		tmp.push(0);
		insertColor(color, index);
		tmp.push(x + w);
		tmp.push(y);
		tmp.push(1);
		tmp.push(0);
		insertColor(color, index);
		tmp.push(x);
		tmp.push(y + h);
		tmp.push(0);
		tmp.push(1);
		insertColor(color, index);
		tmp.push(x + w);
		tmp.push(y + h);
		tmp.push(1);
		tmp.push(1);
		insertColor(color, index);

		if( x < xMin ) xMin = x;
		if( y < yMin ) yMin = y;
		x += w;
		y += h;
		if( x > xMax ) xMax = x;
		if( y > yMax ) yMax = y;
	}

	public inline function rectGradient( x : Float, y : Float, w : Float, h : Float, ctl : Int, ctr : Int, cbl : Int, cbr : Int, index:Int = 0 ) {
		tmp.push(x);
		tmp.push(y);
		tmp.push(0);
		tmp.push(0);
		insertColor(ctl, index);
		tmp.push(x + w);
		tmp.push(y);
		tmp.push(1);
		tmp.push(0);
		insertColor(ctr, index);
		tmp.push(x);
		tmp.push(y + h);
		tmp.push(0);
		tmp.push(1);
		insertColor(cbl, index);
		tmp.push(x + w);
		tmp.push(y + h);
		tmp.push(1);
		tmp.push(0);
		insertColor(cbr, index);

		if( x < xMin ) xMin = x;
		if( y < yMin ) yMin = y;
		x += w;
		y += h;
		if( x > xMax ) xMax = x;
		if( y > yMax ) yMax = y;
	}

	public inline function fillArc( x : Float, y : Float, ray : Float, c : Int, start: Float, end: Float) {
		if (end <= start) return;
		var arcLength = end - start;
		var nsegments = Math.ceil(ray * 3.14 * 2 / 4);
		if ( nsegments < 4 ) nsegments = 4;
		var angle = arcLength / nsegments;
		var prevX = Math.NEGATIVE_INFINITY;
		var prevY = Math.NEGATIVE_INFINITY;
		var _x = 0.;
		var _y = 0.;
		var i = 0;
		while ( i < nsegments ) {
			var a = start + i * angle;
			_x = x + Math.cos(a) * ray;
			_y = y + Math.sin(a) * ray;
			if (prevX != Math.NEGATIVE_INFINITY) {
				addPoint(x, y, c);
				addPoint(_x, _y, c);
				addPoint(prevX, prevY, c);
				addPoint(prevX, prevY, c);
			}
			prevX = _x;
			prevY = _y;
			i += 1;
		}
		var a = end;
		_x = x + Math.cos(a) * ray;
		_y = y + Math.sin(a) * ray;
		addPoint(x, y, c);
		addPoint(_x, _y, c);
		addPoint(prevX, prevY, c);
		addPoint(prevX, prevY, c);
	}

	public inline function fillCircle( x : Float, y : Float, radius : Float, c : Int) {
		var nsegments = Math.ceil(radius * 3.14 * 2 / 2);
		if( nsegments < 3 ) nsegments = 3;
		var angle = Math.PI * 2 / nsegments;
		var prevX = Math.NEGATIVE_INFINITY;
		var prevY = Math.NEGATIVE_INFINITY;
		var firstX = Math.NEGATIVE_INFINITY;
		var firstY = Math.NEGATIVE_INFINITY;
		var curX = 0., curY = 0.;
		for( i in 0...nsegments) {
			var a = i * angle;
			curX = x + Math.cos(a) * radius;
			curY = y + Math.sin(a) * radius;
			if (prevX != Math.NEGATIVE_INFINITY) {
				addPoint(x, y, c);
				addPoint(curX, curY, c);
				addPoint(prevX, prevY, c);
				addPoint(x, y, c);
			}
			if (firstX == Math.NEGATIVE_INFINITY) {
			firstX = curX;
				firstY = curY;
			}
			prevX = curX;
			prevY = curY;
		}
		addPoint(x, y, c);
		addPoint(curX, curY, c);
		addPoint(firstX, firstY, c);
		addPoint(x, y, c);
	}

	public inline function circle( x : Float, y : Float, ray : Float, size: Float, c : Int) {
		if (size > ray) return;
		var nsegments = Math.ceil(ray * 3.14 * 2 / 2);
		if ( nsegments < 3 ) nsegments = 3;
		var ray1 = ray - size;
		var angle = Math.PI * 2 / nsegments;
		var prevX = Math.NEGATIVE_INFINITY;
		var prevY = Math.NEGATIVE_INFINITY;
		var prevX1 = Math.NEGATIVE_INFINITY;
		var prevY1 = Math.NEGATIVE_INFINITY;
		for( i in 0...nsegments ) {
			var a = i * angle;
			var _x = x + Math.cos(a) * ray;
			var _y = y + Math.sin(a) * ray;
			var _x1 = x + Math.cos(a) * ray1;
			var _y1 = y + Math.sin(a) * ray1;
			if (prevX != Math.NEGATIVE_INFINITY) {
				addPoint(_x, _y, c);
				addPoint(prevX, prevY, c);
				addPoint(_x1, _y1, c);
				addPoint(prevX1, prevY1, c);
			}
			prevX = _x;
			prevY = _y;
			prevX1 = _x1;
			prevY1 = _y1;
		}
	}

	public inline function arc( x : Float, y : Float, ray : Float, size: Float, start: Float, end: Float, c : Int) {
		if (size > ray) return;
		if (end <= start) return;
		var arcLength = end - start;
		var nsegments = Math.ceil(ray * 3.14 * 2 / 4);
		if ( nsegments < 3 ) nsegments = 3;
		var ray1 = ray - size;
		var angle = arcLength / nsegments;
		var prevX = Math.NEGATIVE_INFINITY;
		var prevY = Math.NEGATIVE_INFINITY;
		var prevX1 = Math.NEGATIVE_INFINITY;
		var prevY1 = Math.NEGATIVE_INFINITY;
		var _x = 0.;
		var _y = 0.;
		var _x1 = 0.;
		var _y1 = 0.;
		for( i in 0...nsegments ) {
			var a = start + i * angle;
			_x = x + Math.cos(a) * ray;
			_y = y + Math.sin(a) * ray;
			_x1 = x + Math.cos(a) * ray1;
			_y1 = y + Math.sin(a) * ray1;
			if (prevX != Math.NEGATIVE_INFINITY) {
				addPoint(_x, _y, c);
				addPoint(prevX, prevY, c);
				addPoint(_x1, _y1, c);
				addPoint(prevX1, prevY1, c);
			}
			prevX = _x;
			prevY = _y;
			prevX1 = _x1;
			prevY1 = _y1;
		}
		var a = end;
		_x = x + Math.cos(a) * ray;
		_y = y + Math.sin(a) * ray;
		_x1 = x + Math.cos(a) * ray1;
		_y1 = y + Math.sin(a) * ray1;
		addPoint(_x, _y, c);
		addPoint(prevX, prevY, c);
		addPoint(_x1, _y1, c);
		addPoint(prevX1, prevY1, c);
	}

	override public function alloc(engine:h3d.Engine) {
		if( tmp == null ) clear();
		if( tmp.length > 0 )
			buffer = h3d.Buffer.ofFloats(tmp, 9, [Quads, RawFormat]);
	}

	public inline function flush() {
		if( buffer == null || buffer.isDisposed() ) alloc(h3d.Engine.getCurrent());
	}

	public function doRender(engine:h3d.Engine, min, len) {
		flush();
		if( buffer != null )
			engine.renderQuadBuffer(buffer, min, len);
	}
}

class TileGroupExt extends Drawable
{
  
	var content : TileLayerContentExt;
	var curColor : h3d.Vector;

	public var rangeMin : Int;
	public var rangeMax : Int;

  var textureShader:MultiTexture;
  var textureIndex:Array<Texture>;
  
  public function new(?parent:h2d.Object)
  {
    super(parent);
    if (SpriteBatchExt.noTexture == null) SpriteBatchExt.noTexture = Texture.fromColor(0xff0000);
    textureShader = new MultiTexture();
    textureIndex = new Array();
    textureShader.texture1 = SpriteBatchExt.noTexture;
    textureShader.texture2 = SpriteBatchExt.noTexture;
    textureShader.texture3 = SpriteBatchExt.noTexture;
    textureShader.texture4 = SpriteBatchExt.noTexture;
    textureShader.texture5 = SpriteBatchExt.noTexture;
    textureShader.texture6 = SpriteBatchExt.noTexture;
    textureShader.texture7 = SpriteBatchExt.noTexture;
    this.addShader(textureShader);
		rangeMin = rangeMax = -1;
		curColor = new h3d.Vector(1, 1, 1, 1);
		content = new TileLayerContentExt();
  }
  
	override function getBoundsRec( relativeTo : Object, out : h2d.col.Bounds, forSize : Bool ) {
		super.getBoundsRec(relativeTo, out, forSize);
		addBounds(relativeTo, out, content.xMin, content.yMin, content.xMax - content.xMin, content.yMax - content.yMin);
	}
  
  public function clear()
  {
    textureIndex = new Array();
    textureShader.texture1 = SpriteBatchExt.noTexture;
    textureShader.texture2 = SpriteBatchExt.noTexture;
    textureShader.texture3 = SpriteBatchExt.noTexture;
    textureShader.texture4 = SpriteBatchExt.noTexture;
    textureShader.texture5 = SpriteBatchExt.noTexture;
    textureShader.texture6 = SpriteBatchExt.noTexture;
    textureShader.texture7 = SpriteBatchExt.noTexture;
  }
  
	/**
		If you want to add tiles after the GPU memory has been allocated (when the tilegroup with sync/displayed),
		make sure to call invalidate() first to force a refresh of your data.
	**/
	public function invalidate() : Void {
		content.dispose();
	}

	/**
		Returns the number of tiles added to the group
	**/
	public function count() : Int {
		return content.triCount() >> 1;
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

	public inline function add(x : Float, y : Float, t : h2d.Tile) {
		content.add(x, y, curColor.x, curColor.y, curColor.z, curColor.w, t, addRef(t));
	}

	public inline function addColor( x : Float, y : Float, r : Float, g : Float, b : Float, a : Float, t : Tile) {
		content.add(x, y, r, g, b, a, t, addRef(t));
	}

	public inline function addAlpha(x : Float, y : Float, a : Float, t : h2d.Tile) {
		content.add(x, y, curColor.x, curColor.y, curColor.z, a, t, addRef(t));
	}

	public inline function addTransform(x : Float, y : Float, sx : Float, sy : Float, r : Float, t : Tile) {
		content.addTransform(x, y, sx, sy, r, curColor, t, addRef(t));
	}

  function addRef(t:Tile):Int
  {
    var tex = t == null ? SpriteBatchExt.noTexture : t.getTexture();
    if (tex == null) tex = SpriteBatchExt.noTexture;
    var i = 0;
    while (i < 8)
    {
      var ref = textureIndex[i];
      if (ref == null)
      {
        textureIndex[i] = tex;
        switch (i)
        {
          // case 0: this.tile = e.t;
          case 1: this.textureShader.texture1 = tex;
          case 2: this.textureShader.texture2 = tex;
          case 3: this.textureShader.texture3 = tex;
          case 4: this.textureShader.texture4 = tex;
          case 5: this.textureShader.texture5 = tex;
          case 6: this.textureShader.texture6 = tex;
          case 7: this.textureShader.texture7 = tex;
        }
        return i;
      }
      else if (tex == ref) return i;
      i++;
    }
    throw "TileGroupExt multiple texture count limit reached!";
  }

	override function draw(ctx:RenderContext) {
		drawWith(ctx,this);
	}


	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
		// On some mobile GPU, uploading while rendering does create a lot of stall.
		// Let's make sure to force the upload before starting while we are still
		// syncing our 2d scene.
		content.flush();
	}

	@:allow(h2d)
	function drawWith( ctx:RenderContext, obj : Drawable ) {
		var max = content.triCount();
		if( max == 0 )
			return;
		if( !ctx.beginDrawObject(obj, textureIndex[0]) ) return;
		var min = rangeMin < 0 ? 0 : rangeMin * 2;
		if( rangeMax > 0 && rangeMax < max * 2 ) max = rangeMax * 2;
		content.doRender(ctx.engine, min, max - min);
	}

}