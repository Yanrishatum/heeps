package h3d.shader;

import hxsl.Shader;

/**
  An s2d shader that allows binding up to 7 additional textures.
**/
class MultiTexture extends Shader
{
  
  static var SRC = {
    
    // @:import h3d.shader.Base2d;
    
    @input var idxIn : {
      var textureIndex:Float;
    }
    
    var calculatedUV:Vec2;
    var textureColor:Vec4;
    
    @var var texIndex:Int;
    // @param var texture:Sampler2D;
    @param var texture1:Sampler2D;
    @param var texture2:Sampler2D;
    @param var texture3:Sampler2D;
    @param var texture4:Sampler2D;
    @param var texture5:Sampler2D;
    @param var texture6:Sampler2D;
    @param var texture7:Sampler2D;
    
    function __init__()
    {
      texIndex = int(idxIn.textureIndex);
    }
    
    function fragment()
    {
      var t0 = textureColor; // workaround
      if (texIndex == 1) textureColor = texture1.get(calculatedUV);
      else if (texIndex == 2) textureColor = texture2.get(calculatedUV);
      else if (texIndex == 3) textureColor = texture3.get(calculatedUV);
      else if (texIndex == 4) textureColor = texture4.get(calculatedUV);
      else if (texIndex == 5) textureColor = texture5.get(calculatedUV);
      else if (texIndex == 6) textureColor = texture6.get(calculatedUV);
      else if (texIndex == 7) textureColor = texture7.get(calculatedUV);
      else textureColor = t0;
    }
    
  }
  
}