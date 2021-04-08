package ch2.ui;

import h2d.Object;
import h2d.Text;
import hxd.res.DefaultFont;

class DevOverlay extends Object {
  
  public var ui:DevUI;
  var tileContainer:Object;
  var labelContainer:Object;
  public var g:Graphics;
  
  var labels:Array<Text>;
  var labelCount:Int;
  var tiles:Array<Bitmap>;
  var tileCount:Int;
  
  public var manualClear:Bool;
  
  public function new(?parent:Object)
  {
    super(parent);
    this.tileContainer = new Object(this);
    this.g = new Graphics(this);
    this.labelContainer = new Object(this);
    this.ui = new DevUI(this);
    this.ui.autoWatch = true;
    labels = new Array();
    labelCount = 0;
    tiles = new Array();
    tileCount = 0;
  }
  
  public function tileAt(x:Float, y:Float, tile:Tile) {
    var btm:Bitmap;
    if (tiles.length == tileCount) {
      btm = new Bitmap(tile, tileContainer);
      tiles.push(btm);
      tileCount++;
    } else {
      btm = tiles[tileCount++];
      btm.tile = tile;
      btm.visible = true;
    }
    btm.setPosition(x, y);
  }
  
  public function textAt(x:Float, y:Float, label:String, align:Align = Center)
  {
    var text:Text;
    if (labels.length == labelCount)
    {
      text = new Text(DefaultFont.get(), labelContainer);
      text.dropShadow = { dx: 1, dy: 1, color: 0, alpha: 1 };
      labels.push(text);
      labelCount++;
    }
    else
    {
      text = labels[labelCount++];
      text.visible = true;
    }
    text.textAlign = align;
    text.setPosition(x, y);
    text.text = label;
  }
  
  public function line(x0:Float, y0:Float, x1:Float, y1:Float, color:Int, width:Float = 1, alpha:Float = 1) {
    g.lineStyle(width, color, alpha);
    g.moveTo(x0, y0);
    g.lineTo(x1, y1);
    g.lineStyle();
  }
  
  public inline function arrow(x0:Float, y0:Float, x1:Float, y1:Float, color:Int, width:Float = 1, alpha:Float = 1) {
    
    g.lineStyle(width, color, alpha);
    g.moveTo(x0, y0);
    g.lineTo(x1, y1);
    // canvas.lineStyle(shape_outline_width, color, alpha);
    var ang = Math.atan2(y1 - y0, x1 - x0);
    var dx = x1 - Math.cos(ang) * 2 * width;
    var dy = y1 - Math.sin(ang) * 2 * width;
    ang += Math.PI * .5;
    // canvas.moveTo(to_x, to_y);
    var cos = Math.cos(ang) * 2 * width;
    var sin = Math.sin(ang) * 2 * width;
    g.lineTo(dx + cos, dy + sin);
    g.lineTo(dx - cos, dy - sin);
    g.lineTo(x1, y1);
  }
  
  public inline function ray(x:Float, y:Float, nx:Float, ny:Float, color:Int, length = 10., width = 1., alpha = 1.) {
    line(x, y, x + nx * length, y + ny * length, color, width, alpha);
  }
  
  public inline function rayArrow(x:Float, y:Float, nx:Float, ny:Float, color:Int, length = 10., width = 1., alpha = 1.) {
    arrow(x, y, x + nx * length, y + ny * length, color, width, alpha);
  }
  
  public inline function rayAngle(x:Float, y:Float, angle:Float, color:Int, length = 10., width = 1., alpha = 1.) {
    ray(x, y, Math.cos(angle), Math.sin(angle), color, length, width, alpha);
  }
  
  public inline function rayAngleArrow(x:Float, y:Float, angle:Float, color:Int, length = 10., width = 1., alpha = 1.) {
    rayArrow(x, y, Math.cos(angle), Math.sin(angle), color, length, width, alpha);
  }
  
  public function cross(x:Float, y:Float, color:Int, radius:Int = 4, width = 1., alpha = 1.) {
    g.lineStyle(width, color, alpha);
    g.moveTo(x - radius, y);
    g.lineTo(x + radius, y);
    g.moveTo(x, y - radius);
    g.lineTo(x, y + radius);
    g.lineStyle();
  }
  
  override function drawRec(ctx:RenderContext)
  {
    super.drawRec(ctx);
    if (!manualClear) inline clear();
  }
  
  public function clear() {
    while (labelCount > 0) labels[--labelCount].visible = false;
    while (tileCount > 0) tiles[--tileCount].visible = false;
    g.clear();
  }
  
}