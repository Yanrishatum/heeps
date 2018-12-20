package h2d.ui;

import hxd.Event;
import h2d.Tile;

class RadioButton extends Checkbox
{
  private static var bg:Tile;
  private static var check:Tile;
  
  public var group(default, null):RadioGroup;
  public var index(default, null):Int;
  
  public function new(?parent:Object, ?group:RadioGroup)
  {
    super(parent);
    if (bg == null)
    {
      var d:hxd.BitmapData = new hxd.BitmapData(10, 10);
      d.fill(1, 1, 8, 8, 0xffcccccc);
      d.fill(2, 0, 6, 1, 0xffcccccc);
      d.fill(2, 9, 6, 1, 0xffcccccc);
      d.fill(0, 2, 1, 6, 0xffcccccc);
      d.fill(9, 2, 1, 6, 0xffcccccc);
      bg = Tile.fromBitmap(d);
      
      d = new hxd.BitmapData(8, 8);
      d.fill(1, 1, 6, 6, 0xff808080);
      d.fill(2, 0, 4, 1, 0xff808080);
      d.fill(2, 7, 4, 1, 0xff808080);
      d.fill(0, 2, 1, 4, 0xff808080);
      d.fill(7, 2, 1, 4, 0xff808080);
      check = Tile.fromBitmap(d);
      check.dx = 1;
      check.dy = 1;
    }
    
    if (group != null) group.add(this);
    else
    {
      this.group = new RadioGroup();
      this.group.add(this);
    }
  }
  
  override public function setChecked(v:Bool)
  {
    if (v) this.group.selectedIndex = index;
  }
  
  override private function draw(ctx:RenderContext)
  {
    super.draw(ctx);
    emitTile(ctx, bg);
    if (checked) emitTile(ctx, check);
  }
  
  public dynamic function onRadio(value:Int):Void
  {
    
  }
}

@:access(h2d.ui.RadioButton)
class RadioGroup
{
  
  var buttons:Array<RadioButton>;
  
  public var selectedIndex(get, set):Int;
  
  public function new(?buttons:Array<RadioButton>)
  {
    this.buttons = new Array();
    if (buttons != null)
    {
      for (b in buttons) add(b);
    }
  }
  
  function get_selectedIndex()
  {
    for (b in buttons) if (b.checked) return b.index;
    return -1;
  }
  
  function set_selectedIndex(v:Int):Int
  {
    if (v < 0 || v >= buttons.length) return get_selectedIndex();
    if (buttons[v].checked) return v;
    for (b in buttons)
    {
      if (b.index == v)
      {
        b.checked = true;
        b.onChange(true);
      }
      else if (b.checked)
      {
        b.checked = false;
        b.onChange(false);
      }
      b.onRadio(b.index);
    }
    onChange(v);
    return v;
  }
  
  public function add(radio:RadioButton)
  {
    if (radio.group != null) radio.group.remove(radio);
    radio.group = this;
    radio.index = this.buttons.length;
    buttons.push(radio);
  }
  
  public function remove(radio:RadioButton)
  {
    if (buttons.remove(radio))
    {
      radio.group = null;
      var i = 0;
      for (b in buttons) b.index = i++;
    }
  }
  
  public dynamic function onChange(index:Int):Void
  {
    
  }
  
}