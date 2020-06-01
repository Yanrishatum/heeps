package ch2.ui;

import h2d.Object;
import h2d.Text;
import hxd.res.DefaultFont;

class DevOverlay extends Object {
  
  public var ui:DevUI;
  var labelContainer:Object;
  public var g:Graphics;
  
  var labels:Array<Text>;
  var labelCount:Int;
  var labelPool:Int;
  
  public function new(?parent:Object)
  {
    super(parent);
    this.g = new Graphics(this);
    this.labelContainer = new Object(this);
    this.ui = new DevUI(this);
    this.ui.autoWatch = true;
    labels = new Array();
    labelCount = 0;
    labelPool = 0;
  }
  
  public function textAt(x:Float, y:Float, label:String, align:Align = Center)
  {
    var text:Text;
    if (labelPool == labelCount)
    {
      text = new Text(DefaultFont.get(), labelContainer);
      text.dropShadow = { dx: 1, dy: 1, color: 0, alpha: 1 };
      labels.push(text);
      labelPool++;
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
  
  override function drawRec(ctx:RenderContext)
  {
    super.drawRec(ctx);
    while (labelCount > 0)
    {
      labels[--labelCount].visible = false;
    }
    g.clear();
  }
  
}