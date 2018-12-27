package h2d.ui;

import hxd.fs.ManifestFileSystem;
import hxd.res.ManifestLoader;

class ManifestProgress extends h2d.Object
{
  var g:h2d.Graphics;
  var text:h2d.Text;
  
  var loader:ManifestLoader;
  var color:Int;
  var onLoaded:Void->Void;
  
  public function new(loader:ManifestLoader, color:Int = 0xffffff, onLoaded:Void->Void, ?parent:h2d.Object)
  {
    super();
    this.loader = loader;
    this.color = color;
    this.onLoaded = onLoaded;
    
    g = new Graphics(this);
    text = new Text(hxd.res.DefaultFont.get(), this);
    text.y = 50;
    text.textAlign = Center;
    text.textColor = 0xff000000 | color;
  }
  
  public function start():Void
  {
    loader.onLoaded = finish;
    loader.onFileLoadStarted = showFileName;
    loader.onFileLoadStarted = fileLoaded;
    loader.onFileProgress = fileProgress;
    var s = getScene();
    if (s != null)
    {
      text.maxWidth = s.width;
      g.x = s.width * .25;
      y = (s.height - 70) * .5;
    }
    else 
    {
      g.x = 0;
      text.maxWidth = 400;
    }
  }
  
  function setProgress(b:Int, t:Int):Void
  {
    g.clear();
    var s = getScene();
    var size = s != null ? s.width * .5 : 400;
    g.beginFill(color);
    g.drawRect(0, 0, loader.loadedFiles / loader.totalFiles * size, 20);
    if (b != 0 && t != 0) g.drawRect(0, 25, b / t * size, 20);
  }
  
  function finish():Void
  {
    setProgress(1, 1);
    text.text = "All done!";
    onLoaded();
  }
  
  function showFileName(f:ManifestEntry)
  {
    text.text = "Loading: " + f.path;
  }
  
  function fileLoaded(f:ManifestEntry)
  {
    setProgress(1, 1);
    text.text = "Loaded : " + f.path;
  }
  
  function fileProgress(f:ManifestEntry, b:Int, t:Int)
  {
    setProgress(b, t);
  }
  
}