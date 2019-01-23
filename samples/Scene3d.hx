import h2d.ui.Checkbox;
import h2d.Flow;
import h2d.Bitmap;
import h3d.scene.CameraController;
import hxd.Res;
import h3d.scene.TileSprite;
import hxd.App;

class Scene3d extends App
{
  
  static function main() {
    new Scene3d();
  }
  
  override private function loadAssets(onLoaded:() -> Void)
  {
    hxd.Res.initLocal();
    super.loadAssets(onLoaded);
  }
  
  var f:Flow;
  
  override private function init()
  {
    super.init();
    
    f = new Flow(s2d);
    f.isVertical = true;
    f.verticalSpacing = 4;
    f.padding = 10;
    
    inline function check(label:String, _get:()->Bool, _set:(v:Bool)->Void )
    {
      var line = new Flow(f);
      line.verticalAlign = Middle;
      var c = new Checkbox(line);
      var l = new h2d.ui.Label(label, null, Left, 300, c, line);
      l.text.x = 5;
      c.onChange = (v) -> { _set(v); c.checked = _get(); }
      c.checked = _get();
    }
    
    new CameraController(s3d);
    
    // Axes helper
    new h3d.scene.Axes(s3d);
    
    // Tile sprite
    
    var t = Res.confirm.toTile();
    t.dx = Std.int(-t.width / 2);
    t.dy = Std.int(-t.height / 2);
    var s = new TileSprite(t, 64, true, s3d);
    s.material.texture.filter = Nearest;
    
    check("TileSprite: faceZAxis", () -> s.faceZAxis, (v) -> s.faceZAxis = v);

    // TODO: S2DPlane
    
  }
  
}