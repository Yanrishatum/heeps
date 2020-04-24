package ch3.shader;

import h3d.Vector;

class PaletteShader extends hxsl.Shader {
  
  static var SRC = {
    
    @const @param var PALETTE_SIZE:Int;
    @const var TEST_APPROX:Bool = false;
    @const var TEST_ALPHA:Bool = false;
    @param var SRC_COL:Array<Vec4, PALETTE_SIZE>;
    @param var DST_COL:Array<Vec4, PALETTE_SIZE>;
    var textureColor:Vec4;
    
    function testeq(a:Vec4, b:Vec4):Bool {
      if (TEST_APPROX) {
        if (TEST_ALPHA) {
          return a.r - 1e-10 >= b.r && a.r + 1e-10 <= b.r &&
                 a.g - 1e-10 >= b.g && a.g + 1e-10 <= b.g &&
                 a.b - 1e-10 >= b.b && a.b + 1e-10 <= b.b &&
                 a.a - 1e-10 >= b.a && a.a + 1e-10 <= b.a;
        } else {
          return a.r - 1e-10 >= b.r && a.r + 1e-10 <= b.r &&
                 a.g - 1e-10 >= b.g && a.g + 1e-10 <= b.g &&
                 a.b - 1e-10 >= b.b && a.b + 1e-10 <= b.b;
        }
      } else {
        
        if (TEST_ALPHA) {
          return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
        } else {
          return a.r == b.r && a.g == b.g && a.b == b.b;
        }
      }
    }
    
    function fragment() {
      var tc = textureColor;
      for (i in 0...PALETTE_SIZE) {
        if (testeq(tc, SRC_COL[i])) {
          if (TEST_ALPHA) textureColor = DST_COL[i];
          else textureColor.rgb = DST_COL[i].rgb;
          break;
        }
      }
    }
    
  }
  
  public function new(pal:Map<Int, Int>) {
    super();
    setPalette(pal);
  }
  
  public function setPalette(pal:Map<Int, Int>) {
    PALETTE_SIZE = Lambda.count(pal);
    var i = 0;
    for (kv in pal.keyValueIterator()) {
      SRC_COL[i] = new Vector();
      SRC_COL[i].setColor(kv.key);
      DST_COL[i] = new Vector();
      DST_COL[i].setColor(kv.value);
      i++;
    }
  }
  
}