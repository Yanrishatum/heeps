package cherry.res;

import haxe.Json;
import hxd.res.Resource;

class JsonFile extends Resource {
  
  public inline function toJson<T:Dynamic>():T {
    return haxe.Json.parse(entry.getText());
  }
  
  public inline function getText():String {
    return entry.getText();
  }
  
  public function toParticles(?parent:h2d.Object):h2d.Particles {
    var json = toJson();
    if (json.type != "particles2D") throw "Not a particles json!";
    var parts = new h2d.Particles(parent);
    parts.load(json, entry.path);
    return parts;
  }
  
  // public function toParticles3
  
}