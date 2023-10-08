package ch2.ui;

import h2d.Object;
import h2d.Text;
import hxd.res.DefaultFont;

private class LineKeepAlive {
  
  static var pool: LineKeepAlive;
  static var lines: LineKeepAlive;
  static var lineTail: LineKeepAlive;
  
  public static function get(x0:Float, y0:Float, x1:Float, y1:Float, color:Int, width:Float, alpha:Float, keepAlive: Int): LineKeepAlive {
    if (pool == null) return new LineKeepAlive().set(x0, y0, x1, y1, color, width, alpha, keepAlive);
    else {
      var l = pool;
      pool = pool.next;
      return l.set(x0, y0, x1, y1, color, width, alpha, keepAlive);
    }
  }
  
  public var x0: Float;
  public var y0: Float;
  public var x1: Float;
  public var y1: Float;
  public var color: Int;
  public var width: Float;
  public var alpha: Float;
  public var keepAlive: Int;
  public var next: LineKeepAlive;
  public var prev: LineKeepAlive;
  
  public function new() {}
  
  public function put() {
    if (next != null) next.prev = prev;
    if (prev != null) prev.next = next;
    prev = null;
    next = pool;
    pool = this;
  }
  
  public function set(x0:Float, y0:Float, x1:Float, y1:Float, color:Int, width:Float, alpha:Float, keepAlive: Int) {
    this.x0 = x0;
    this.y0 = y0;
    this.x1 = x1;
    this.y1 = y1;
    this.color = color;
    this.width = width;
    this.alpha = alpha;
    this.keepAlive = keepAlive;
    next = null;
    prev = null;
    return this;
  }
}
class DevOverlay extends Object {
  
  public var ui:DevUI;
  var tileContainer:Object;
  var labelContainer:Object;
  public var g:Graphics;
  
  var labels:Array<Text>;
  var labelCount:Int;
  var tiles:Array<Bitmap>;
  var tileCount:Int;
  var lineHead: LineKeepAlive;
  var lineTail: LineKeepAlive;
  
  public var manualClear:Bool;
  
  public function new(?parent:Object)
  {
    super(parent);
    this.tileContainer = new Object(this);
    this.g = new Graphics(this);
    this.g.filter = new h2d.filter.Nothing();
    this.g.filter.resolutionScale = 2;
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
  
  public function line(x0:Float, y0:Float, x1:Float, y1:Float, color:Int, width:Float = 1, alpha:Float = 1, keepAlive: Int = 0) {
    // g.beginFill(color, alpha);
    // var hw = width * .5;
    // var angle = Math.atan2(y1 - y0, x1 - x0) + dn.M.PIHALF;
    // var c = Math.cos(angle) * 0;
    // var s = Math.sin(angle) * hw;
    // g.lineTo(x0 - s, y0 + s);
    // g.lineTo(x1 - s, y0 + s);
    // g.lineTo(x1 + s, y1 - s);
    // g.lineTo(x0 + s, y1 - s);
    // g.endFill();
    // Someone broke two-point lines.
    g.lineStyle(width, color, alpha);
    g.moveTo(x0, y0);
    g.lineTo(x1, y1 + hxd.Math.EPSILON);
    g.lineStyle();
    if (keepAlive > 0) {
      var line:LineKeepAlive = LineKeepAlive.get(x0, y0, x1, y1, color, width, alpha, keepAlive);
      if (lineHead == null) lineHead = lineTail = line;
      else {
        lineTail.next = line;
        line.prev = lineTail;
        lineTail = line;
      }
    }
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
  
  public inline function ray(x:Float, y:Float, nx:Float, ny:Float, color:Int, length = 10., width = 1., alpha = 1., keepAlive: Int = 0) {
    line(x, y, x + nx * length, y + ny * length, color, width, alpha, keepAlive);
  }
  
  public inline function rayArrow(x:Float, y:Float, nx:Float, ny:Float, color:Int, length = 10., width = 1., alpha = 1.) {
    arrow(x, y, x + nx * length, y + ny * length, color, width, alpha);
  }
  
  public inline function rayAngle(x:Float, y:Float, angle:Float, color:Int, length = 10., width = 1., alpha = 1., keepAlive: Int = 0) {
    ray(x, y, Math.cos(angle), Math.sin(angle), color, length, width, alpha, keepAlive);
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
  
  override function sync(ctx:RenderContext) {
    var l = lineHead;
    while (l != null) {
      line(l.x0, l.y0, l.x1, l.y1, l.color, l.width, l.alpha, 0);
      l = l.next;
    }
    super.sync(ctx);
  }
  
  override function drawRec(ctx:RenderContext)
  {
    super.drawRec(ctx);
    if (!manualClear) inline clear();
  }
  
  public function clear() {
    while (labelCount > 0) labels[--labelCount].visible = false;
    while (tileCount > 0) tiles[--tileCount].visible = false;
    var l = lineHead;
    while (l != null) {
      if (--l.keepAlive <= 0) {
        if (l == lineTail) lineTail = l.prev;
        if (l == lineHead) lineHead = l.next;
        var n = l.next;
        l.put();
        l = n;
      } else l = l.next;
    }
    g.clear();
  }
  
}