package cherry.plugins.generic.shaders;

class CheckerShader extends hxsl.Shader {
  
  static var SRC = {
    // @:import h3d.shader.Base2d;
    
    @param var checkerSize:Float = 8;
    @param var blackColor:Vec4;
    @param var whiteColor:Vec4;
    var pixelColor:Vec4;
    @var var calculatedUV:Vec2;
    
    function fragment() {
      var tvec = calculatedUV / checkerSize;
      var black = (tvec.x % 2) < 1;
      if ((tvec.y % 2) < 1) black = !black;
      if (black) {
        pixelColor.rgb = blackColor.rgb;
        pixelColor.a *= blackColor.a;
      } else {
        pixelColor.rgb = whiteColor.rgb;
        pixelColor.a *= whiteColor.a;
      }
    }
  }
  
  public function new(?white:h3d.Vector, ?black:h3d.Vector) {
    super();
    if (white != null) this.whiteColor = white;
    else this.whiteColor.setColor(0xff333333);
    // else this.whiteColor.setColor(0xffffffff);
    if (black != null) this.blackColor = black;
    else this.blackColor.setColor(0xff111111);
    // else this.blackColor.setColor(0xffcccccc);
  }
  
}
