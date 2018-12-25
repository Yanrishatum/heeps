package h3d.scene;

import h3d.mat.Material;
import h2d.Tile;
import h3d.prim.PlanePrim;

@:access(h2d.Tile)
class TileSprite extends Mesh
{
  
  public var faceCamera:Bool;
  // When false - will track camera on X and Y axes, but will always look at Z=0
  public var faceZAxis:Bool;
  public var tile(default, set):Tile;
  var ppu:Float;
  public var pixelsPerUnit(default, set):Float;
  var plane:PlanePrim;
  
  public function new(tile:Tile, ppu:Float = 1, faceCamera:Bool = true, ?parent:Object)
  {
    this.faceCamera = faceCamera;
    this.faceZAxis = true;
    this.plane = new PlanePrim(1, 1, X);
    var mat = Material.create(tile.getTexture());
    mat.blendMode = Alpha;
    super(plane, mat, parent);
    
    this.pixelsPerUnit = ppu;
    this.tile = tile;
    alwaysSync = true;
  }
  
  function set_tile(t:Tile):Tile
  {
    if (t == null)
    {
      // Do something
    }
    else
    {
      plane.set(t.width * ppu, t.height * ppu, t.u, t.v, t.u2, t.v2, t.dx * ppu, t.dy * ppu);
      material.texture = t.getTexture();
    }
    return this.tile = t;
  }
  
  function set_pixelsPerUnit(v:Float):Float
  {
    ppu = 1 / v;
    if (tile != null) set_tile(tile);
    return pixelsPerUnit = v;
  }
  
  override private function syncRec(ctx:RenderContext)
  {
    if (faceCamera)
    {
      var up = ctx.scene.camera.up;
      var vec = ctx.scene.camera.pos.sub(ctx.scene.camera.target);
      if (!faceZAxis) vec.z = 0;
      // // var oldX = qRot.x;
      // // var oldY = qRot.y;
      // // var oldZ = qRot.z;
      // // var oldW = qRot.w;
      qRot.initRotateMatrix(Matrix.lookAtX(vec, up));
      this.posChanged = true;
    }
    super.syncRec(ctx);
  }
  
}