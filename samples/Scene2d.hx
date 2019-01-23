import h2d.HtmlText;
import h2d.Text;
import h2d.ui.RadioButton;
import h2d.Interactive;
import h2d.ui.Button;
import h2d.Flow;
import h2d.Scene;
import hxd.App;
import h2d.ui.*;

class Scene2d extends App
{
  
  override private function loadAssets(onLoaded:() -> Void)
  {
    hxd.Res.initLocal();
    super.loadAssets(onLoaded);
  }
  
  override private function init()
  {
    super.init();
    setScene2D(new UISample());
  }
  
}

class UISample extends Scene
{
  
  public function new()
  {
    super();
    
    var f:Flow = new Flow(this);
    f.isVertical = true;
    f.verticalSpacing = 5;
    f.padding = 10;
    var line:Flow;
    
    inline function newLine(spacing:Int = 3)
    {
      line = new Flow(f);
      line.horizontalSpacing = spacing;
      line.verticalAlign = Middle;
    }
    
    inline function withLabel(text:String, i:Interactive)
    {
      new Label(text, null, null, null, i, i.parent);
    }
    
    new Button(200, 20, "A primitive Button", f);
    newLine(3);
    withLabel("A Checkbox and a Label", new Checkbox(line));
    
    newLine(3);
    var g = new RadioGroup();
    withLabel("A RadioButton", new RadioButton(line, g));
    withLabel("2", new RadioButton(line, g));
    withLabel("3", new RadioButton(line, g));
    withLabel("4", new RadioButton(line, g));
    
    var idle = new Text(hxd.res.DefaultFont.get());
    idle.text = "A SimpleButton: idle";
    var hover = new Text(hxd.res.DefaultFont.get());
    hover.text = "A SimpleButton: Hover";
    var press = new Text(hxd.res.DefaultFont.get());
    press.text = "A SimpleButton: Press";
    var disabled = new Text(hxd.res.DefaultFont.get());
    disabled.text = "A SimpleButton: Disabled";
    new SimpleButton(200, 20, idle, hover, press, null, f);
    new SimpleButton(200, 20, disabled, disabled, disabled, disabled, f).enabled = false;
    
    var scroll = new ScrollText(new HtmlText(hxd.res.DefaultFont.get()), 200, 150, f);
    scroll.hookListeners();
    scroll.htmlText.maxWidth = scroll.width;
    scroll.htmlText.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras quis ultricies dolor. Ut et eros ultricies, suscipit est a, posuere tortor. Suspendisse condimentum, elit vel pharetra aliquet, lorem sapien ultricies mauris, vitae vehicula urna ligula malesuada nulla. Nulla maximus vulputate tristique. Ut eleifend nunc id quam tempor egestas. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Quisque varius, orci et finibus ultrices, dolor risus dapibus nulla, et dictum justo lacus sed nisl. Nam dignissim nisi egestas orci tempor, ut consectetur sapien consequat. Aliquam fermentum quam et orci gravida tristique. Suspendisse ultricies odio dolor, in placerat enim pharetra sit amet. Cras et augue vel justo tincidunt tincidunt. Nunc blandit porttitor varius.";
    
    // TODO: ScrollArea
    // TODO: ScrollBar
  }
  
}