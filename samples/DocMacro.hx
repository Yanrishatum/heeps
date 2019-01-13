package samples;

import haxe.io.Path;
import sys.FileSystem;
import haxe.macro.Context;

class DocMacro
{
  #if macro
  
  static var files:Array<String> = [];
  
  static function include(pack:String)
  {
		var displayValue = Context.definedValue("display");
    
		var prefix = pack == '' ? '' : pack + '.';
		var found = false;
    var cp = ".";
		var path = pack == '' ? cp : cp + "/" + pack.split(".").join("/");
		if( !sys.FileSystem.exists(path) || !sys.FileSystem.isDirectory(path) )
      return;
		found = true;
		for( file in sys.FileSystem.readDirectory(path) ) {
			if( file != "import.hx" && StringTools.endsWith(file, ".hx") && file.substr(0, file.length - 3).indexOf(".") < 0 ) {
				var cl = prefix + file.substr(0, file.length - 3);
				Context.getModule(cl);
        files.push(StringTools.replace(cl, ".", "[./\\\\]"));
			} else if( sys.FileSystem.isDirectory(path + "/" + file))
				include(prefix + file);
		}
  }
  
  static function store()
  {
    sys.io.File.saveContent("docs/doc.inc", files.join("\n"));
  }
  
  #end
  
  static macro function getFiles()
  {
    var el = [for (f in files) macro $v{f}];
    return macro $a{el};
  }
  
  static function main()
  {
    var flist:Array<String> = sys.io.File.getContent("docs/doc.inc").split("\n");
    var cmd = ["run", "dox", "-i", "docs", "-o", "docs"];
    for (f in flist)
    {
      cmd.push("-in");
      cmd.push(f);
    }
    trace("File count: " + flist.length);
    Sys.command("haxelib", cmd);
  }
  
}