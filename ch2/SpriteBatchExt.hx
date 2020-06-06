package ch2;

import h2d.Tile;
import h2d.Object;
import hxd.FloatBuffer;
import h3d.mat.Texture;
import ch3.shader.MultiTexture;
import h2d.SpriteBatch;

/**
  Experimental SpriteBatch with support of up to 8 different textures.
**/
@:access(h2d.Tile)
class SpriteBatchExt extends SpriteBatch
{
  var textureShader:MultiTexture;
  var textureIndex:Array<TextureRef>;
  
  public function new(?parent:Object)
  {
    super(null, parent);
    textureShader = new MultiTexture();
    textureIndex = new Array();
    this.addShader(textureShader);
  }
  
  override public function add(e:BatchElement, before:Bool = false):BatchElement
  {
    super.add(e, before);
    var i = 0;
    while (i < 8)
    {
      var ref = textureIndex[i];
      if (ref == null)
      {
        ref = { texture: e.t.getTexture(), tile: e.t, refCount: 1 };
        textureIndex[i] = ref;
        switch (i)
        {
          case 0: this.tile = e.t;
          case 1: this.textureShader.texture1 = ref.texture;
          case 2: this.textureShader.texture2 = ref.texture;
          case 3: this.textureShader.texture3 = ref.texture;
          case 4: this.textureShader.texture4 = ref.texture;
          case 5: this.textureShader.texture5 = ref.texture;
          case 6: this.textureShader.texture6 = ref.texture;
          case 7: this.textureShader.texture7 = ref.texture;
        }
        break;
      }
      else if (ref.texture == e.t.getTexture())
      {
        ref.refCount++;
        break;
      }
      i++;
    }
    if (i == 8) throw "SpriteBatchExt multiple texture count limit reached!";
    return e;
  }
  
  override public function clear()
  {
    super.clear();
    textureIndex = new Array();
    textureShader.clearTextures();
    tile = null;
  }
  
  override private function delete(e:BatchElement)
  {
    super.delete(e);
    var tex = e.t.getTexture();
    var i = 0;
    while (i < textureIndex.length)
    {
      var ref = textureIndex[i];
      if (ref.texture == tex)
      {
        if (--ref.refCount == 0)
        {
          textureIndex.remove(ref);
          repopulate();
        }
        break;
      }
      i++;
    }
  }
  
  function repopulate()
  {
    textureShader.clearTextures();
    if (textureIndex.length == 0)
    {
      tile = null;
    }
    else 
    {
      tile = textureIndex[0].tile;
      var len = textureIndex.length;
      var i = 0;
      if (++i != len) textureShader.texture1 = textureIndex[i].texture;
      if (++i != len) textureShader.texture2 = textureIndex[i].texture;
      if (++i != len) textureShader.texture3 = textureIndex[i].texture;
      if (++i != len) textureShader.texture4 = textureIndex[i].texture;
      if (++i != len) textureShader.texture5 = textureIndex[i].texture;
      if (++i != len) textureShader.texture6 = textureIndex[i].texture;
      if (i+1 != len) textureShader.texture7 = textureIndex[i].texture;
    }
  }
  
  override private function flush()
  {
    if (first == null)
    {
      bufferVertices = 0;
      return;
    }
    if (tmpBuf == null) tmpBuf = new FloatBuffer();
    var pos = 0;
    var e = first;
    var tmp = tmpBuf;
    var ti = textureIndex;
    var til = textureIndex.length;
    while (e != null)
    {
      if (!e.visible)
      {
        e = e.next;
        continue;
      }
      
      var t = e.t;
      tmp.grow(pos + 9 * 4);
      var tex = t.getTexture();
      var texIndex = 0;
      while (texIndex < til)
      {
        if (ti[texIndex].texture == tex) break;
        texIndex++;
      }
      
      inline function fillRest():Void
      {
				tmp[pos++] = e.r;
				tmp[pos++] = e.g;
				tmp[pos++] = e.b;
				tmp[pos++] = e.a;
        tmp[pos++] = texIndex;
      }
      
			if( hasRotationScale )
      {
				var ca = Math.cos(e.rotation), sa = Math.sin(e.rotation);
				var hx = t.width, hy = t.height;
				var px = t.dx * e.scaleX, py = t.dy * e.scaleY;
				tmp[pos++] = px * ca - py * sa + e.x;
				tmp[pos++] = py * ca + px * sa + e.y;
				tmp[pos++] = t.u;
				tmp[pos++] = t.v;
        fillRest();
				var px = (t.dx + hx) * e.scaleX, py = t.dy * e.scaleY;
				tmp[pos++] = px * ca - py * sa + e.x;
				tmp[pos++] = py * ca + px * sa + e.y;
				tmp[pos++] = t.u2;
				tmp[pos++] = t.v;
        fillRest();
				var px = t.dx * e.scaleX, py = (t.dy + hy) * e.scaleY;
				tmp[pos++] = px * ca - py * sa + e.x;
				tmp[pos++] = py * ca + px * sa + e.y;
				tmp[pos++] = t.u;
				tmp[pos++] = t.v2;
        fillRest();
				var px = (t.dx + hx) * e.scaleX, py = (t.dy + hy) * e.scaleY;
				tmp[pos++] = px * ca - py * sa + e.x;
				tmp[pos++] = py * ca + px * sa + e.y;
				tmp[pos++] = t.u2;
				tmp[pos++] = t.v2;
        fillRest();
			}
      else
      {
				var sx = e.x + t.dx;
				var sy = e.y + t.dy;
				tmp[pos++] = sx;
				tmp[pos++] = sy;
				tmp[pos++] = t.u;
				tmp[pos++] = t.v;
        fillRest();
				tmp[pos++] = sx + t.width + 0.1;
				tmp[pos++] = sy;
				tmp[pos++] = t.u2;
				tmp[pos++] = t.v;
        fillRest();
				tmp[pos++] = sx;
				tmp[pos++] = sy + t.height + 0.1;
				tmp[pos++] = t.u;
				tmp[pos++] = t.v2;
        fillRest();
				tmp[pos++] = sx + t.width + 0.1;
				tmp[pos++] = sy + t.height + 0.1;
				tmp[pos++] = t.u2;
				tmp[pos++] = t.v2;
        fillRest();
			}
      
      e = e.next;
    }
		bufferVertices = Std.int(pos / 9);
		if( buffer != null && !buffer.isDisposed() ) {
			if( buffer.vertices >= bufferVertices ){
				buffer.uploadVector(tmpBuf, 0, bufferVertices);
				return;
			}
			buffer.dispose();
			buffer = null;
		}
		if( bufferVertices > 0 )
			buffer = h3d.Buffer.ofSubFloats(tmpBuf, 9, bufferVertices, [Dynamic, Quads, RawFormat]);
  }
  
}

@:structInit
class TextureRef
{
  
  public var texture:Texture;
  public var tile:Tile;
  public var refCount:Int;
  
}