package h3d.scene;

class Axes extends Object
{
  
  public function new(?parent:Object)
  {
    super(parent);
    
    var ax = new h3d.scene.Box(0xFFFF0000, true, this);
    ax.x = 0.5;
    ax.scaleY = 0.001;
    ax.scaleZ = 0.001;

    var ay = new h3d.scene.Box(0xFF00FF00, true, this);
    ay.y = 0.5;
    ay.scaleX = 0.001;
    ay.scaleZ = 0.001;

    var az = new h3d.scene.Box(0xFF0000FF, true, this);
    az.z = 0.5;
    az.scaleX = 0.001;
    az.scaleY = 0.001;
  }
  
}