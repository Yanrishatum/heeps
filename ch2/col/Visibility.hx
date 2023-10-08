package ch2.col;
#if echo
import echo.math.Vector2;

import echo.shape.Rect;
import echo.shape.Polygon;
import echo.shape.Circle;
import echo.Body;
import echo.World;
import echo.Shape;
import echo.Line;

class Visibility {
  
  public var objects:Array<Body>;
  // TODO: Circle
  var ray:Line;
  
  public function new(objects:Array<Body>) {
    this.objects = objects;
    this.ray = Line.get(0, 0);
  }
  
  public function visibilityRadius(x:Float, y:Float, radius:Float) {
    ray.x = x;
    ray.y = y;
    var ray = Line.get(x, y);
    var x0 = x - radius;
    var y0 = y - radius;
    var x1 = x + radius;
    var y1 = y + radius;
    var bounds = new Body();
    bounds.shape = Rect.get_from_min_max(x0, y0, x1, y1);
    objects.push(bounds);
    var test = echo.util.AABB.get();
    var points:Array<Vector2> = [];
    for (o in objects) {
      o.bounds(test);
      var tl = test.min_x;
      var tr = tl + test.width;
      var tt = test.min_y;
      var tb = tt + test.height;
      
      function castRay() {
        var inter = ray.linecast(objects);
        if (inter != null) {
          // if (inter.body == o) {
            var dist = inter.data[0].distance;
            points.push(inter.data[0].hit.clone());
            inter.put();
            var base = ray.end.clone();
            ray.end = (base - ray.start).rotate(0.000001, Vector2.zero) + ray.start;
            inter = ray.linecast(objects);
            if (inter != null) {
              if (inter.data[0].distance > dist)
                points.push(inter.data[0].hit.clone());
              inter.put();
            }
            ray.end = (base - ray.start).rotate(-0.000001, Vector2.zero) + ray.start;
            inter = ray.linecast(objects);
            if (inter != null) {
              if (inter.data[0].distance > dist)
                points.push(inter.data[0].hit.clone());
              inter.put();
            }
          // }
          if (inter != null) inter.put();
        } else {
          // Reached the limit
          // inter = ray.linecast(bounds);
          // if (inter != null) points.push(inter.data[0].hit.clone());
        }
      }
      
      // if (tl < x1 && tr >= x0 && tt < y1 && tb >= y0) {
        for (s in o.shapes) {
          switch (s.type) {
            case CIRCLE: throw "TODO: Circle";
            case POLYGON:
              var poly = Std.downcast(s, Polygon);
              for (pt in poly.vertices) {
                ray.dx = pt.x;
                ray.dy = pt.y;
                castRay();
              }
            case RECT: 
              var rect = Std.downcast(s, Rect);
              ray.dx = rect.left;
              ray.dy = rect.top;
              castRay();
              ray.dx = rect.right;
              castRay();
              ray.dy = rect.bottom;
              castRay();
              ray.dx = rect.left;
              castRay();
          }
        }
      // }
    }
    
    objects.pop();
    return points;
  }
  
}
#end