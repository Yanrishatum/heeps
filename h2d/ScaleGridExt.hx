package h2d;

/**
  Extended ScaleGrid: Allows for tiling of center and borders have individual sizes.
**/
class ScaleGridExt extends h2d.TileGroup {
	
	/**
		Height of the top border.
	**/
  public var borderTop(default, set):Int;
	/**
		Height of the bottom border.
	**/
  public var borderBottom(default, set):Int;
	/**
		Width of the left border.
	**/
  public var borderLeft(default, set):Int;
	/**
		Height of the right border.
	**/
  public var borderRight(default, set):Int;

	/**
		Width of the ScaleGrid.
	**/
	public var width(default,set) : Int;
	/**
		Height of the ScaleGrid.
	**/
	public var height(default,set) : Int;

	/**
		If true, borders will be tiled instead of stretched.
	**/
	public var tileBorders(default, set) : Bool;
	/**
		If true, central part will be tiled instead of stretched.
	**/
  public var tileCenter(default, set) : Bool;

	public function new( tile, borderT, borderB, borderL, borderR, ?parent ) {
		super(tile,parent);
		borderTop = borderT;
    borderBottom = borderB;
    borderLeft = borderL;
    borderRight = borderR;
    width = Std.int(tile.width);
		height = Std.int(tile.height);
	}

	function set_tileBorders(b) {
		this.tileBorders = b;
		clear();
		return b;
	}
  
  function set_tileCenter(b) {
    this.tileCenter = b;
    clear();
    return b;
  }

	function set_width(w) {
		this.width = w;
		clear();
		return w;
	}

	function set_height(h) {
		this.height = h;
		clear();
		return h;
	}

	function set_borderTop(v) {
		this.borderTop = v;
		clear();
		return v;
	}

	function set_borderBottom(v) {
		this.borderBottom = v;
		clear();
		return v;
	}

	function set_borderLeft(v) {
		this.borderLeft = v;
		clear();
		return v;
	}

	function set_borderRight(v) {
		this.borderRight = v;
		clear();
		return v;
	}

	override function getBoundsRec(relativeTo, out, forSize) {
		if( content.isEmpty() ) updateContent();
		super.getBoundsRec(relativeTo, out, forSize);
	}

	function updateContent() {
    var bt = borderTop;
    var bb = borderBottom;
    var bl = borderLeft;
    var br = borderRight;
    var curColor = this.curColor;
    var tile = this.tile;
    var content = this.content;

		// 4 corners
    if (bt > 0)
    {
  		if (bl > 0) content.addColor(0, 0, curColor, tile.sub(0, 0, bl, bt));
  		if (br > 0) content.addColor(width - br, 0, curColor, tile.sub(tile.width - br, 0, br, bt));
    }
    if (bb > 0)
    {
      if (bl > 0) content.addColor(0, height-bb, curColor, tile.sub(0, tile.height - bb, bl, bb));
  		if (br > 0) content.addColor(width - br, height - bb, curColor, tile.sub(tile.width - br, tile.height - bb, br, bb));
    }

		var sizeX = Std.int(tile.width) - bl - br;
		var sizeY = Std.int(tile.height) - bt - bb;
    
    var rw = -1;
    var rh = -1;
    var dx = -1;
    var dy = -1;
    
    inline function calcTiling()
    {
			rw = Std.int((width - br - bl) / sizeX);
			dx = width - br - bl - rw * sizeX;
			rh = Std.int((height - bt - bb) / sizeY);
			dy = height - bt - bb - rh * sizeY;
    }

		if( !tileBorders ) {

			var w = width - bl - br;
			var h = height - bt - bb;

			var t = tile.sub(bl, 0, sizeX, bt);
			t.scaleToSize(w, bt);
			content.addColor(bl, 0, curColor, t);

			var t = tile.sub(bl, tile.height - bb, sizeX, bb);
			t.scaleToSize(w, bb);
			content.addColor(bl, h + bt, curColor, t);
			
			var t = tile.sub(0, bt, bl, sizeY);
			t.scaleToSize(bl, h);
			content.addColor(0, bt, curColor, t);

			var t = tile.sub(tile.width - br, bt, br, sizeY);
			t.scaleToSize(br, h);
			content.addColor(w + bl, bt, curColor, t);

		} else {
      calcTiling();
			for( x in 0...rw ) {
				content.addColor(bl + x * sizeX, 0, curColor, tile.sub(bl, 0, sizeX, bt));
				content.addColor(bl + x * sizeX, height - bb, curColor, tile.sub(bl, tile.height - bb, sizeX, bb));
			}
			if( dx > 0 ) {
				content.addColor(bl + rw * sizeX, 0, curColor, tile.sub(bl, 0, dx, bt));
				content.addColor(bl + rw * sizeX, height - bb, curColor, tile.sub(bl, tile.height - bb, dx, bb));
			}

			for( y in 0...rh ) {
				content.addColor(0, bt + y * sizeY, curColor, tile.sub(0, bt, bl, sizeY));
				content.addColor(width - br, bt + y * sizeY, curColor, tile.sub(tile.width - br, bt, br, sizeY));
			}
			if( dy > 0 ) {
				content.addColor(0, bt + rh * sizeY, curColor, tile.sub(0, bt, bl, dy));
				content.addColor(width - br, bt + rh * sizeY, curColor, tile.sub(tile.width - br, bt, br, dy));
			}
		}
    
    if (!tileCenter) {
  		var t = tile.sub(bl, bt, sizeX, sizeY);
  		t.scaleToSize(width - bl - br,height - br - bb);
  		content.addColor(bl, bt, curColor, t);
    } else {
      if (rw == -1) calcTiling();
      var t = tile.sub(bl, bt, sizeX, sizeY);
      var tx = null;
      var ty = null;
      if (dx > 0) tx = tile.sub(bl, bt, dx, sizeY);
      if (dy > 0) ty = tile.sub(bl, bt, sizeX, dy);
      for (y in 0...rh) {
        for (x in 0...rw) {
          content.addColor(bl + x * sizeX, bt + y * sizeY, curColor, t);
        }
        if (dx > 0) {
          content.addColor(width - br - sizeX, bt + y * sizeY, curColor, tx);
        }
      }
      if (dy > 0) {
        var y = height - bb - sizeY;
        for (x in 0...rw) {
          content.addColor(bl + x * sizeX, y, curColor, ty);
        }
        if (dx > 0) {
          content.addColor(width - br - sizeX, y, curColor, tile.sub(bl, bt, dx, dy));
        }
      }
    }
	}

	override function sync( ctx : RenderContext ) {
		if( content.isEmpty() ) {
			content.dispose();
			updateContent();
		}
		super.sync(ctx);
	}

}