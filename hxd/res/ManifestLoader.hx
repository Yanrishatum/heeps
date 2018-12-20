package hxd.res;

import hxd.fs.ManifestFileSystem;

class ManifestLoader extends hxd.res.Loader
{
  
  var mfs:ManifestFileSystem;
  
  public var totalFiles(default, null):Int;
  public var loadedFiles(default, null):Int;
  public var loading(default, null):Bool;
  
  var entries:Iterator<ManifestEntry>;
  var current:ManifestEntry;
  
  public function new(fs:ManifestFileSystem)
  {
    super(fs);
    mfs = fs;
    totalFiles = Lambda.count(fs.manifest);
    loadedFiles = 0;
    loading = false;
  }
  
  public function loadManifestFiles()
  {
    if (!loading)
    {
      loading = true;
      entries = mfs.manifest.iterator();
      next();
    }
  }
  
  private function next():Void
  {
    if (current != null)
    {
      loadedFiles++;
      onFileLoaded(current);
    }
    if (entries.hasNext())
    {
      current = entries.next();
      onFileLoadStarted(current);
      current.fancyLoad(next, fileProgress);
    }
    else 
    {
      current = null;
      loading = false;
      onLoaded();
    }
  }
  
  private function fileProgress(loaded:Int, total:Int):Void
  {
    if (current != null) onFileProgress(current, loaded, total);
  }
  
  // Called when loader starts loading of specific file.
  public dynamic function onFileLoadStarted(file:ManifestEntry):Void
  {
    
  }
  
  // Called during file loading. loaded and total refer to loaded bytes and total file size.
  public dynamic function onFileProgress(file:ManifestEntry, loaded:Int, total:Int):Void
  {
    
  }
  
  // Called when file is loaded.
  public dynamic function onFileLoaded(file:ManifestEntry):Void
  {
    
  }
  
  public dynamic function onLoaded():Void
  {
    
  }
  
}