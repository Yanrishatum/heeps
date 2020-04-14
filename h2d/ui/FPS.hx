package h2d.ui;

import h2d.Flow;
import hxd.Timer;

/**
  Primitive FPS counter.
  Adapted from openfl.display.FPS
**/
class FPS extends Object
{
  
  public var currentFPS(default, null):Int;
  public var averageFPS(default, null):Int;
  public var minFPS(default, null):Int;
  public var maxFPS(default, null):Int;
  
  var graph:Bitmap;
  var graphShader:GraphShader;
  
  var stats:Text;
  var avgStat:Text;
  var minStat:Text;
  var maxStat:Text;
  
  var resolution:Int;
  var packedResolution:Int;
  var frames:haxe.ds.Vector<Int>;
  
  public var goodThreshold:Int = 60;
  public var cautionThreshold:Int = 30;
  
  public function new(resolution:Int = 150, ?parent:Object)
  {
    super(parent);
    currentFPS = 0;
    
    var fnt = hxd.res.DefaultFont.get();
    var f = new h2d.Flow(this);
    f.maxWidth = resolution;
    f.minWidth = resolution;
    f.horizontalSpacing = 4;
    // f.debug = true;
    avgStat = new Text(fnt, f);
    avgStat.textAlign = MultilineRight;
    minStat = new Text(fnt, f);
    minStat.textAlign = MultilineRight;
    maxStat = new Text(fnt, f);
    maxStat.textAlign = MultilineRight;
    stats = new Text(fnt, this);
    stats.textAlign = Right;
    stats.x = resolution;
    
    if (resolution > 512) resolution = 512;
    else if (resolution < 10) resolution = 10;
    this.resolution = resolution;
    
    graph = new Bitmap(Tile.fromColor(0xffffff, resolution, 60), this);
    graph.y = fnt.lineHeight * 2;
    graphShader = new GraphShader();
    graphShader.graphValuesCount = resolution;
    graphShader.height = 60;
    graph.addShader(graphShader);
    packedResolution = Math.ceil(resolution / 4);
    graphShader.GraphValuesSize = packedResolution;
    for (i in 0...packedResolution) graphShader.graphValues[i] = new h3d.Vector(0,0,0,0);
    
    frames = new haxe.ds.Vector(resolution);
    // for (i in 0...resolution) frames[i] = goodThreshold;
  }
  
  public function alignSelf(hor:FlowAlign = Right, ver:FlowAlign = Top) {
    switch (hor) {
      // case Left: x = 5;
      case Right: x = getScene().width - resolution - 5;
      case Middle: x = Math.round((getScene().width - resolution) / 2);
      default: x = 5;
    }
    switch (ver) {
      // case Top: y = 5;
      case Bottom: y = getScene().height - graph.y - graph.height - 5;
      case Middle: y = Math.round((getScene().height - graph.y - graph.height) / 2);
      default: y = 5;
    }
  }
  
  override private function sync(ctx:RenderContext)
  {
    super.sync(ctx);
    var ts = Std.int(1/Timer.elapsedTime);
    
    var max = 0;
    var min = ts;
    
    var arr = frames;
    var sum = 0;
    for (i in 0...resolution-1)
    {
      var v = arr[i+1];
      arr[i] = v;
      sum += v;
      if (max < v) max = v;
      if (min > v) min = v;
    }
    arr[resolution-1] = ts;
    sum += ts;
    if (max < ts) max = ts;
    
    // max = this.max = this.max < 1 || this.max < max ? max : this.max - 1;
    var oi = 0;
    for (i in 0...packedResolution)
    {
      graphShader.graphValues[i].set(arr[oi++] / max, arr[oi++] / max, arr[oi++] / max, arr[oi++] / max);
    }
    graphShader.average = (sum / resolution) / max;
    graphShader.goodThreshold = goodThreshold / max;
    graphShader.cautionThreshold = cautionThreshold / max;
    // monitor avg
    
    currentFPS = ts;
    averageFPS = Std.int(sum / resolution);
    minFPS = min;
    maxFPS = max;
    
    // TODO: Less expensive stat display.
    // inline function pad(v:Int) return StringTools.lpad("" + v, " ", 3);
    avgStat.text = "AVG\n" + averageFPS;
    minStat.text = "MIN\n" + min;
    maxStat.text = "MAX\n" + max;
    stats.text = ts + " FPS\n" + Math.round(Timer.elapsedTime * 10000)/10 + "ms";
    
    // Lag-gen
    // var j = 0;
    // var i = 0;
    // while (i < Math.random() * 500000) {
    //   j = j + 1 & 8; i++;
    // }
    
    #if hl
    // var stats = hl.Gc.stats();
    // TODO: Memory stats
    #end
  }
  
}

// Port of shader from Graphy
// https://github.com/Tayx94/graphy/blob/master/Assets/Tayx/Graphy%20-%20Ultimate%20Stats%20Monitor/Shaders/GraphStandard.shader
class GraphShader extends hxsl.Shader {
  
  static var SRC = {
    
    var pixelColor : Vec4;
    @var var calculatedUV : Vec2; 
    
    @param var goodColor:Vec4 = vec4(0.462745,0.831372,0.227450,1);
    @param var cautionColor:Vec4 = vec4(0.952941,0.909803,0,1);
    @param var criticalColor:Vec4 = vec4(0.862745,0.160784,0.117647,1);
    @param var goodThreshold:Float = 0.5;
    @param var cautionThreshold:Float = 0.25;
    
    @param var average:Float;
    // NOTE: The size of this array can break compatibility with some older GPUs
    // If you see a pink box or that the graphs are not working, try lowering this value
    // or using the GraphMobile.shader
    // Port note: It's a hacky implementation, because Heaps does not allow using `Array<Float, Size>` and complains it should be 4-component-aligned.
    @param @const var GraphValuesSize : Int; // 512/4
    @param var graphValues : Array<Vec4, GraphValuesSize>;
    @param var graphValuesCount : Float;
    // Graph height. Used to do more precise graph bars so they won't jump in thickness.
    @param var height:Float = 0;
    
    function fragment() {
      var xCoord = calculatedUV.x;
      var yCoord = 1 - calculatedUV.y;
      
      var pxSize = if (height != 0) 1 / height else 0.02;
      
      var color : Vec4;
      if (yCoord < average && yCoord > average - pxSize) {
        // Average white bar
        color = vec4(1,1,1,1);
      } else if (yCoord < cautionThreshold && yCoord > cautionThreshold - pxSize) {
        // CautionColor bar
        color = cautionColor;
      } else if (yCoord < goodThreshold && yCoord > goodThreshold - pxSize) {
        // GoodColor bar
        color = goodColor;
      } else {
        var index = int(xCoord * graphValuesCount);
        var packed = graphValues[int(index / 4)];
        index %= 4;
        var graphValue = if (index == 0) packed.r else if (index == 1) packed.g else if (index == 3) packed.b else packed.a;
        
        if (yCoord > graphValue) {
          // Set as transparent the part on top of the current point value
          discard;
        } else {
          // Assign the corresponding color
          if (graphValue > goodThreshold) {
            color = goodColor;
          } else if (graphValue > cautionThreshold) {
            color = cautionColor;
          } else {
            color = criticalColor;
          }
          // Point coloring
          if (graphValue - yCoord > (1. / (graphValuesCount - 1.)) * 4) {
            // color.a = yCoord * graphValue * .3;
            color.a = yCoord * .3 / graphValue;
          }
        }
      }

      // Fade the alpha of the sides of the graph
      if (xCoord < 0.03) {
        color.a *= 1 - (0.03 - xCoord) / 0.03;
      } else if (xCoord > 0.97) {
        color.a *= (1 - xCoord) / 0.03;
      }
      pixelColor = color;
    }
  }
}