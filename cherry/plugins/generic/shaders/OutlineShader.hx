package cherry.plugins.generic.shaders;

class OutlineShader extends hxsl.Shader {
  
  static var SRC = {
    
    @global var time:Float;
    @param var outlineColor:Vec4;
    @param var checkerSize:Float = 6;
    @param var speed:Float = 5;
    @param var blackColor:Vec4;
    @param var whiteColor:Vec4;
    @const var animate:Bool = true;
    @const var absolute:Bool = false;
    var pixelColor:Vec4;
    var absolutePosition:Vec4;
    var spritePosition:Vec4;
    
    function fragment() {
      if (pixelColor.r == outlineColor.r && pixelColor.g == outlineColor.g && pixelColor.b == outlineColor.b) {
        var tvec = ((absolute ? absolutePosition.xy : spritePosition.xy) - (animate ? time * speed : 0)) / vec2(checkerSize, checkerSize);
        if (((tvec.x + tvec.y) % 2) < 1) {
          pixelColor.rgb = blackColor.rgb;
          pixelColor.a *= blackColor.a;
        } else {
          pixelColor.rgb = whiteColor.rgb;
          pixelColor.a *= whiteColor.a;
        }
      }
      
    }
    
  }
  
  public function new(?white:h3d.Vector, ?black:h3d.Vector) {
    super();
    outlineColor.set(1, 0 ,0);
    if (white != null) this.whiteColor = white;
    else this.whiteColor.set(1,1,1);
    if (black != null) this.blackColor = black;
    else this.blackColor.set(0,0,0);
  }
  
}
