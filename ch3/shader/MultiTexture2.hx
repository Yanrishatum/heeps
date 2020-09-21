package ch3.shader;

import h3d.mat.Texture;

class MultiTexture2 extends hxsl.Shader {
  
  static var SRC = {
    
    // @:import h3d.shader.Base2d;
    
    @input var idxIn : {
      var textureIndex:Float;
    }
    var calculatedUV:Vec2;
    var textureColor:Vec4;
    @var var texIndex:Float;
    
    @const @param var TEXTURE_COUNT:Int = 7;
    @param var textures:Array<Sampler2D, TEXTURE_COUNT>;
    
    function __init__()
    {
      texIndex = idxIn.textureIndex;
    }
    
    function fragment()
    {
      var col = textureColor;
      var index = int(texIndex);
      if (index > 0) {
        col = textures[index - 1].get(calculatedUV);
      }
      textureColor = col;
    }
    
  }
  
  public function new(count:Int = 7) {
    super();
    var tex = Texture.fromColor(0xff00ff);
    textures = [for (i in 0...count) tex];
    TEXTURE_COUNT = count;
  }
  
}