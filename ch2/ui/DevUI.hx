package ch2.ui;

import h2d.Bitmap;
import h2d.Tile;
import h2d.Interactive;
import h2d.RenderContext;
import h2d.Dropdown;
import h2d.Object;
import hxd.Event;
import hxd.Math;
import hxd.BitmapData;
import h2d.Text;
import hxd.res.DefaultFont;
import h2d.Flow;

class DevUI extends Flow {
  
  var groupStack:Array<Flow>;
  var group:Flow;
  
  public var autoWatch:Bool = false;
  var watchers:Array<IWatcher>;
  
  public function new(?parent:Object)
  {
    super(parent);
    layout = Vertical;
    watchers = new Array();
    groupStack = [];
    group = this;
  }
  
  public function button(label:String, callback:Void->Void)
  {
    var b:Button = new Button(label, group);
    b.onClick = (_) -> callback();
    return b;
  }
  
  public function label(text:String, align:Align = Left, color:Int = 0xffffff)
  {
    var t:Text = new Text(DefaultFont.get(), group);
    t.textAlign = align;
    t.textColor = color;
    return t;
  }
  
  public function checkbox(get:Void->Bool, set:Bool->Void, ?label:String, watch:Bool = false)
  {
    var c = new Checkbox(group, label);
    c.checked = get();
    c.onChange = (v) -> { set(v); };
    if (watch || autoWatch) watchers.push(new WatchCheckbox(get, c));
    return c;
  }
  
  public function dropdown(get:Void->Int, set:Int->Void, name:String, labels:Array<String>, watch:Bool = false)
  {
    var f = new Flow(group);
    var fnt = DefaultFont.get();
    var t = new Text(fnt, f);
    t.text = name;
    var d = new Dropdown(f);
    for (l in labels)
    {
      var t = new Text(fnt);
      d.addItem(t);
    }
    d.selectedItem = get();
    d.onClose = () -> set(d.selectedItem);
    if (watch || autoWatch) watchers.push(new WatchDropdown(d, get));
    return d;
  }
  
  // public function dropdownEnum(get:Void->Enum, set:Enum->Void, name:String)
  
  // TODO: Slider
  // TODO: Enums
  // TODO: Radio
  // public function addRadioGroup(get:Void->Int, set:Int->Void, name:String, labels:Array<String>, vertical:Bool, watch:Bool = false)
  // {
  //   var f = vertical ? beingGroup(name) : beginFlowGroup(Horizontal);
  //   if (!vertical)
  //   {
      
  //   }
  // }
  
  public function stat(get:Void->String, ?label:String)
  {
    var t = new Text(DefaultFont.get(), group);
    var w = new WatchStat(t, get, label);
    w.invalidate();
    watchers.push(w);
    return t;
  }
  
  public function statI(get:Void->Int, ?label:String)
  {
    return stat( () -> Std.string(get()), label);
  }
  
  public function statF(get:Void->Float, ?label:String)
  {
    return stat( () -> Std.string(Math.fmt(get())), label);
  }
  
  public function object(obj:Object)
  {
    group.addChild(obj);
  }
  
  
  public function beginGroup(name:String, open:Bool = true)
  {
    var fold = new GroupFold(name, group);
    var g:Flow = new Flow(group);
    fold.group = g;
    g.layout = Vertical;
    addGroup(g);
    fold.set(open);
    return g;
  }
  
  public function beginFlowGroup(layout:FlowLayout)
  {
    var g:Flow = new Flow(group);
    g.layout = layout;
    addGroup(g);
    return g;
  }
  
  inline function addGroup(g:Flow)
  {
    groupStack.push(group);
    group = g;
  }
  
  public function endGroup()
  {
    if (groupStack.length > 0) group = groupStack.pop();
  }
  
  override function sync(ctx:RenderContext)
  {
    for (w in watchers) w.invalidate();
    super.sync(ctx);
  }
  
}

private interface IWatcher
{
  function invalidate():Void;
}

private class WatchDropdown implements IWatcher {
  var d:Dropdown;
  var get:Void->Int;
  public function new(d:Dropdown, get:Void->Int)
  {
    this.d = d;
    this.get = get;
  }
  
  public function invalidate()
  {
    if (this.d.dropdownList.parent == this.d)
      this.d.selectedItem = get();
  }
  
}

private class WatchStat implements IWatcher {
  
  var t:Text;
  var get:Void->String;
  var prefix:String;
  
  public function new(t:Text, get:Void->String, prefix:String)
  {
    this.t = t;
    this.get = get;
    this.prefix = prefix == null ? "" : (prefix + ": ");
  }
  
  public function invalidate()
  {
    this.t.text = prefix + get();
  }
  
}

private class WatchCheckbox implements IWatcher {
  
  var c:Checkbox;
  var get:Void->Bool;
  
  public function new(get:Void->Bool, c:Checkbox)
  {
    this.c = c;
    this.get = get;
  }
  
  public function invalidate() {
    this.c.checked = get();
  }
  
}

private class GroupFold extends Interactive {
  
  static var _arrow:Tile;
  static var _rot:Float;
  
  var arrow:Bitmap;
  var label:Text;
  
  public var group:Object;
  
  var shown:Bool;
  
  public function new(text:String, ?parent:Object)
  {
    super(0, 12, parent);
    if (_arrow == null)
    {
      var d = new BitmapData(8, 8);
      d.fill(1, 1, 1, 6, 0xff808080);
      d.fill(3, 1, 1, 6, 0xff808080);
      d.fill(4, 1, 1, 6, 0xff808080);
      d.fill(5, 2, 1, 4, 0xff808080);
      d.fill(6, 3, 1, 2, 0xff808080);
      _arrow = Tile.fromBitmap(d);
      _arrow.dx = -4;
      _arrow.dy = -4;
      _rot = Math.PI * .5;
    }
    arrow = new Bitmap(_arrow, this);
    arrow.setPosition(6, 6);
    label = new Text(DefaultFont.get(), this);
    label.x = 12;
    label.text = text;
    width = label.textWidth + 12;
  }
  
  override public function onClick(e:Event)
  {
    set(!shown);
  }
  
  public inline function set(open:Bool)
  {
    shown = open;
    group.visible = open;
  }
  
  override function sync(ctx:RenderContext)
  {
    arrow.rotation = Math.lerp(arrow.rotation, shown ? _rot : 0, 0.1);
    super.sync(ctx);
  }
  
}