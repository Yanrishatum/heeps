package hxd.heeps;

import hxd.fs.Convert;
using format.gif.Tools;

class GifConvert extends Convert {
  
  
  public function new()
  {
    super("gif", "giff");
  }
  
  override public function convert()
  {
    var input = new haxe.io.BytesInput(srcBytes);
    var data = new format.gif.Reader(input).read();
    var w = data.logicalScreenDescriptor.width;
    var h = data.logicalScreenDescriptor.height;
    var fc = data.framesCount();
    
    var mo = #if gif_disable_margin 0 #else 1 #end;
    var mh = #if gif_disable_margin h #else h + 2 #end;
    var ls = w * 4;
    var frameSize = w * mh * 4;
    
    var image = haxe.io.Bytes.alloc(frameSize * fc);
    var output = new haxe.io.BytesOutput();
    output.writeString("GIFF");
    output.writeUInt16(0);
    output.writeUInt16(fc);
    output.writeInt32(w);
    output.writeInt32(h);
    for (i in 0...fc) {
      // TODO: Optimize positioning, deduplicate.
      var gc = data.graphicControl(i);
      var frame = data.extractFullBGRA(i);
      output.writeInt32(0); // x
      output.writeInt32(i * mh + mo); // y
      output.writeInt32(gc.delay == 0 ? 10 : gc.delay * 10); // delay
      image.blit(frameSize * i + (ls * mo), frame, 0, frame.length);
      #if !gif_disable_margin
      image.blit(frameSize * i, frame, 0, ls);
      image.blit(frameSize * (i+1) - ls, frame, frame.length - ls, ls);
      #end
    }
    
    var imageOut = new haxe.io.BytesOutput();
    new format.png.Writer(imageOut).write(format.png.Tools.build32BGRA(w, mh * fc, image));
    hxd.File.saveBytes(haxe.io.Path.withExtension(srcPath, "png"), imageOut.getBytes());
    save(output.getBytes());
  }
  
}