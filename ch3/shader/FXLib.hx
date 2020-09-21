package ch3.shader;

class FXLib extends hxsl.Shader {
  
  static var SRC = {
    
    // 0.5, 20, 1
    function distortX(uv:Vec2, time:Float, amplitude:Float, magnitude:Float, speed:Float):Vec2 {
      uv.x += amplitude * sin(magnitude * radians(360) * uv.y + speed * radians(360) * time);
      return uv;
    }
    
    function distortY(uv:Vec2, time:Float, amplitude:Float, magnitude:Float, speed:Float):Vec2 {
      uv.y += amplitude * sin(magnitude * radians(360) * uv.x + speed * radians(360) * time);
      return uv;
    }
    
  }
  
}