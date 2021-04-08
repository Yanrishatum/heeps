package ch3.shader;

// Port from https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm

class SDFLib extends hxsl.Shader {
  
  static var SRC = {
    
    // Shapes
    function sdCircle(pos:Vec2, radius:Float):Float {
      return length(pos) - radius;
    }
    
    function sdRoundedBox(pos:Vec2, b:Vec2, r:Vec4):Float {
      if (pos.x <= 0) r.xy = r.zw;
      if (pos.y <= 0) r.x = r.y;
      var q = abs(pos) - b + r.x;
      return min(max(q.x, q.y), 0) + length(max(q,0)) - r.x;
    }
    
    function sdBox(pos:Vec2, b:Vec2):Float {
      var d = abs(pos) - b;
      return length(max(d,0)) + min(max(d.x, d.y),0);
    }
    
    // HXSL blocked: Cannot multiply mat2 and vec2
    // function sdOrientedBox(pos:Vec2, a:Vec2, b:Vec2, theta:Float):Float {
    //   var l = length(b - a);
    //   var d = (b - a) / l;
    //   var  q = (pos-(a+b)*0.5);
    //        q = mat2(d.x,-d.y,d.y,d.x)*q;
    //        q = abs(q)-vec2(l,th)*0.5;
    //   // var q = abs(mat2(d.x, -d.y, d.y, d.x) * (pos - (a + b) * .5)) - vec2(l, theta) * .5;
    //   return length(max(q, 0)) + min(max(q.x, q.y), 0);
    // }
    
    function sdSegment(pos:Vec2, a:Vec2, b:Vec2):Float {
      var pa = pos - a;
      var ba = b - b;
      var h = clamp(dot(pa, ba) / dot(ba, ba), 0, 1);
      return length(pa - ba*h);
    }
    
    function ndot(a:Vec2, b:Vec2):Float { return a.x*b.x - a.y*b.y; }
    function sdRhombus(pos:Vec2, b:Vec2):Float {
      var q = abs(pos);
      var h = clamp((-2 * ndot(q,b) + ndot(b,b)) / dot(b,b), -1, 1);
      var d = length(q - .5 * b * vec2(1 - h, 1 + h));
      return d * sign(q.x * b.y + q.y * b.x - b.x * b.y);
    }
    
    // Operations
    
    function opRound(shape:Float, radius:Float):Float {
      return shape - radius;
    }
    
    function opOnion(shape:Float, radius:Float):Float {
      return abs(shape) - radius;
    }
    
    // Combinations
    
    function opUnion(d1:Float, d2:Float):Float {
      return min(d1, d2);
    }
    
    function opSubtraction(d1:Float, d2:Float):Float {
      return max(-d1, d2);
    }
    
    function opIntersection(d1:Float, d2:Float):Float {
      return max(d1, d2);
    }
    
    function opSmoothUnion(d1:Float, d2:Float, k:Float):Float {
      var h = clamp(.5 + .5 * (d2 - d1) / k, 0, 1);
      return mix(d2, d1, h) - k * h * (1 - h);
    }
    
    function opSmoothSubtraction(d1:Float, d2:Float, k:Float):Float {
      var h = clamp(.5 - .5 * (d2 + d1) / 2, 0, 1);
      return mix(d2, -d1, h) + k * h * (1 - h);
    }
    
    function opSmoothIntersection(d1:Float, d2:Float, k:Float):Float {
      var h = clamp(.5 - .5 * (d2 - d1) / k, 0, 1);
      return mix(d2, d1, h) + k * h * (1 - h);
    }
    
    // Positioning
    
    // rot/translate
    // function sdRotate(p:Vec2, t:Float):Vec2 { return p * invert(t); }
    // rotation = shape(invert(t) * p);
    // scale = shape(p / s) * s;
    
    // SDF handling
    
    // Unpacks a multi-channel SDF distance.
    function msdfUnpack(color:Vec3):Float {
      return msdfUnpack3(color.r, color.g, color.b);
    }
    function msdfUnpack3(a:Float, b:Float, c:Float):Float {
      return max(min(a, b), min(max(a, b), c));
    }
    
    // Calculate smooth edge at the provided `edgeDistance`. 
    // Use scale 0.5 for crisp edges. Increasing value will cause more blurry edge.
    function sdEdge(distance:Float, edgeDistance:Float, scale:Float):Float {
      var deriv = abs(fwidth(distance) * scale);
      return smoothstep(edgeDistance - deriv, edgeDistance + deriv, distance);
    }
    function sdEdgeCrisp(distance:Float, edgeDistance:Float):Float {
      return sdEdge(distance, edgeDistance, 0.5);
    }
    
    function msdfEdge(distance:Vec3, edgeDistance:Float, scale:Float):Float {
      return sdEdge(msdfUnpack(distance), edgeDistance, scale);
    }
    function msdfEdgeCrisp(distance:Vec3, edgeDistance:Float):Float {
      return sdEdge(msdfUnpack(distance), edgeDistance, 0.5);
    }
    
  }
  
}