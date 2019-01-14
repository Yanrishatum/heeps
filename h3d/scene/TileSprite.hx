package h3d.scene;

import h3d.mat.Material;
import h2d.Tile;
import h3d.prim.PlanePrim;

/**
  A classic 2D sprite that can follow camera orientation to always face it.
  Sprite front is X forward.
**/
@:access(h2d.Tile)
class TileSprite extends Mesh
{
  /**
    If true, will follow camera orientation to always appear facing X coordinate at camera. (default: true)
  **/
  public var faceCamera:Bool;
  /**
    If true, will track camera on Z axis, otherwise only X and Y coordinates will be adjusted, and sprite will look forward at all times. (default: true)
  **/
  public var faceZAxis:Bool;
  // TODO: zAxis rotation.
  /**
    Currently displayed `h2d.Tile`.
  **/
  public var tile(default, set):Tile;
  var ppu:Float;
  /**
    Pixels per unit value. Affects the sprite size in 3D space. (default: 1)
  **/
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
      var oldX = qRot.x;
      var oldY = qRot.y;
      var oldZ = qRot.z;
      var oldW = qRot.w;
      qRot.initRotateMatrix(Matrix.lookAtX(vec, up));
      if (oldX != qRot.x || oldY != qRot.y || oldZ != qRot.z || oldW != qRot.w)
        this.posChanged = true;
    }
    super.syncRec(ctx);
  }
  
}