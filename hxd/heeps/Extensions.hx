package hxd.heeps;

import haxe.macro.Expr;
using hxd.heeps.ClassExtensionTools;

class Extensions
{
  #if macro
  public static function init():Void
  {
    if (haxe.macro.Context.defined("heeps_disable_patch")) return;
    
    inline function patch(pack:String, ?extra:Array<String>):Bool
    {
      var name = "patch_" + pack.split(".").join("_");
      if (!haxe.macro.Context.defined("heeps_disable_" + name.toLowerCase()))
      {
        haxe.macro.Compiler.addMetadata("@:build(hxd.heeps.Extensions." + name + "())", pack);
        if (extra != null) for (s in extra)
        {
          name = "patch_" + s.split(".").join("_");
          haxe.macro.Compiler.addMetadata("@:build(hxd.heeps.Extensions." + name + "())", s);
        }
        return true;
      }
      return false;
    }
    
    patch("h2d.Object");
    // patch("h2d.Layers"); // TODO: Fix
  }
  #end
  
  public static function patch_h2d_Object():Array<Field>
  {
    var fields:Array<Field> = haxe.macro.Context.getBuildFields();
    
    var cl = macro class Dummy {
      
      /**
        Transformation origin of an Object.
      **/
      public var originX(default, set):Float;
      /**
        Transformation origin of an Object.
      **/
      public var originY(default, set):Float;
      
      // Complicates calculation of position a lot
      // public var skewX(default, set):Float;
      // public var skewY(default, set):Float;
      
      /**
        Custom overriding transform matrix. Keep in mind, that it does not get reapplied on change.
        When set, all other values (x,y,scale,rotation) are ignored.
      **/
      public var transform(default, set):h2d.col.Matrix;
      /**
        When true, will ignore parent matrix.
      **/
      public var absoluteTransform:Bool;
      
      inline function set_originX(v:Float):Float
      {
        this.posChanged = true;
        return this.originX = v;
      }
      
      inline function set_originY(v:Float):Float
      {
        this.posChanged = true;
        return this.originY = v;
      }
      
      // function set_skewX(v:Float):Float
      // {
      //   this.posChanged = true;
      //   return this.skewX = v;
      // }
      
      // function set_skewY(v:Float):Float
      // {
      //   this.posChanged = true;
      //   return this.skewY = v;
      // }
      
      inline function set_transform(v)
      {
        this.posChanged = true;
        return this.transform = v;
      }
      
      function new()
      {
        originX = 0;
        originY = 0;
        __super;
      }
      
      function calcAbsPos()
      {
        if (transform != null) {
          if (parent == null || absoluteTransform) {
            matA = transform.a;
            matB = transform.b;
            matC = transform.c;
            matD = transform.d;
            absX = transform.x;
            absY = transform.y;
          } else {
            matA = transform.a * parent.matA + transform.b * parent.matC;
            matB = transform.a * parent.matB + transform.b * parent.matD;
            matC = transform.c * parent.matA + transform.d * parent.matC;
            matD = transform.c * parent.matB + transform.d * parent.matD;
            absX = transform.x * parent.matA + transform.y * parent.matC + parent.absX;
            absY = transform.x * parent.matB + transform.y * parent.matD + parent.absY;
          }
        }
        else if( parent == null ) {
          var cr, sr;
          if( rotation == 0 ) {
            cr = 1.; sr = 0.;
            matA = scaleX;
            // matB = scaleX * skewY;
            // matC = scaleY * skewX;
            matB = 0;
            matC = 0;
            matD = scaleY;
          } else {
            cr = Math.cos(rotation);
            sr = Math.sin(rotation);
            matA = scaleX * cr;
            matB = scaleX * sr;
            matC = scaleY * -sr;
            matD = scaleY * cr;
          }
          // if ( skewX != 0 || skewY != 0 ) {
          //   var tanX = Math.tan(skewX);
          //   var tanY = Math.tan(skewY);
          //   var tmpA = matA;
          //   var tmpB = matB;
          //   var tmpC = matC;
          //   var tmpD = matD;
          // }
          absX = x - originX;
          absY = y - originY;
        } else {
          // M(rel) = S . R . T
          // M(abs) = M(rel) . P(abs)
          if( rotation == 0 ) {
            matA = scaleX * parent.matA;
            matB = scaleX * parent.matB;
            matC = scaleY * parent.matC;
            matD = scaleY * parent.matD;
          } else {
            var cr = Math.cos(rotation);
            var sr = Math.sin(rotation);
            var tmpA = scaleX * cr;
            var tmpB = scaleX * sr;
            var tmpC = scaleY * -sr;
            var tmpD = scaleY * cr;
            matA = tmpA * parent.matA + tmpB * parent.matC;
            matB = tmpA * parent.matB + tmpB * parent.matD;
            matC = tmpC * parent.matA + tmpD * parent.matC;
            matD = tmpC * parent.matB + tmpD * parent.matD;
          }
          var ox = x - originX;
          var oy = y - originY;
          absX = ox * parent.matA + oy * parent.matC + parent.absX;
          absY = ox * parent.matB + oy * parent.matD + parent.absY;
        }
      }
    }
    
    fields.merge(cl.fields);
    
    return fields;
  }
  
  public static function patch_h2d_Layers():Array<Field>
  {
    
    var cl = macro class Dummy
    {
      
      /**
        Adds an Object to specified layer and specified index of that layer.
      **/
      public function addAt(s:h2d.Object, layer:Int, index:Int):Void
      {
        if ( layer >= layerCount ) {
          add(s, layer);
          return;
        }

        if ( s.parent == this ) {
          var old = s.allocated;
          s.allocated = false;
          removeChild(s);
          s.allocated = old;
        }
        if ( index <= 0 ) {
          super.addChildAt(s, layer == 0 ? 0 : layersIndexes[layer - 1]);
        } else {
          var start = layer == 0 ? 0 : layersIndexes[layer - 1];
          if (layersIndexes[layer] - start >= index)
            super.addChildAt(s, layersIndexes[layer]);
          else
            super.addChildAt(s, start + index);
        }

        for ( i in layer...layerCount )
          layersIndexes[i]++;
      }
      
      /**
        Moves Object to specified index on it's layer.
      **/
      public function moveChild( s : h2d.Object, index : Int ) {
        for( i in 0...children.length )
          if ( children[i] == s ) {
            var pos = 0;
            for ( l in layersIndexes )
              if ( l > i ) {
                if ( index >= (l - pos) ) index = l - pos - 1;
                break;
              } else {
                pos = l;
              }
            if ( (i - pos) > index ) { // under
              if ( index > 0 ) pos += index;
              var p = i;
              while ( p > pos ) {
                children[p] = children[p - 1];
                p--;
              }
            } else { // over
              pos += index;
              for ( p in i...pos )
                children[p] = children[p + 1];
            }
            children[pos] = s;
            if ( s.allocated )
              s.onHierarchyMoved(false);
            return;
          }
      }
      /**
        Finds the index of a child in it's layer.  
        Always returns -1 if provided Object is not a child of Layer.
      **/
      public function getChildLayerIndex( s : Object ) : Int {
        if ( s.parent != this ) return -1;

        var index = this.children.indexOf(s);
        for ( i in 0...this.layerCount )
          if ( this.layersIndexes[i] > index ) return (i == 0 ? index : index - this.layersIndexes[i - 1]);
        return -1;
      }
      
    }
    var fields = haxe.macro.Context.getBuildFields();
    fields.merge(cl.fields);
    return fields;
  }
  
}