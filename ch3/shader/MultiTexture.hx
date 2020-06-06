package ch3.shader;

import h3d.mat.Texture;
import hxsl.Shader;

/**
  An s2d shader that allows binding up to 7 additional textures.
**/
class MultiTexture extends Shader
{
  
  @:isVar public static var noTexture(get, null):Texture;
  static function get_noTexture() {
    if (noTexture == null) noTexture = Texture.fromColor(0xff0000);
    return noTexture;
  }
  
  static var SRC = {
    
    // @:import h3d.shader.Base2d;
    
    @input var idxIn : {
      var textureIndex:Float;
    }
    
    var calculatedUV:Vec2;
    var textureColor:Vec4;
    
    @var var texIndex:Float;
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
      texIndex = idxIn.textureIndex;
    }
    
    function fragment()
    {
      var t0 = textureColor; // workaround
      var index = int(texIndex);
      if (index == 1) textureColor = texture1.get(calculatedUV);
      else if (index == 2) textureColor = texture2.get(calculatedUV);
      else if (index == 3) textureColor = texture3.get(calculatedUV);
      else if (index == 4) textureColor = texture4.get(calculatedUV);
      else if (index == 5) textureColor = texture5.get(calculatedUV);
      else if (index == 6) textureColor = texture6.get(calculatedUV);
      else if (index == 7) textureColor = texture7.get(calculatedUV);
      else textureColor = t0;
    }
    
  }
  
  public function new() {
    super();
    inline clearTextures();
  }
  
  public function clearTextures() {
    texture1 = noTexture;
    texture2 = noTexture;
    texture3 = noTexture;
    texture4 = noTexture;
    texture5 = noTexture;
    texture6 = noTexture;
    texture7 = noTexture;
  }
  
}