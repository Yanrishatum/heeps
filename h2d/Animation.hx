package h2d;

/**
	Single Animation Frame. Can be reused multiple times in Animation.
**/
class AnimationFrame {

	/**
		An `h2d.Tile` this frame should display. Can be null to show nothing.
	**/
	public var tile : Null<h2d.Tile>;

	/**
		Frame display duration in seconds.
	**/
	public var duration : Float;

	/**
		Is this frame a keyframe? (default: true)
		Keyframes are not skipped when Animation accumulated more than one frame between updates.
	**/
	public var isKey : Bool;

	/**
		Override color multiplier for this frame.
	**/
	public var color : Null<h3d.Vector>;

	/**
		Alpha value for this frame. Shortcut to `color.a`, and will create it as [1, 1, 1, alpha] if it's null.
	**/
	public var alpha(get, set) : Float;

	// TODO: Expand parametrization: dx/dy, colorAdd, colorKey, colorMatrix, blendMode, tileWrap

	/**
		Create a new Animation Frame with specified tile (or null), duration and keyframe flag.
	**/
	public function new( tile : Null<h2d.Tile>, duration : Float, isKey = true ) {
		this.tile = tile;
		this.duration = duration;
		this.isKey = isKey;
	}

	inline function get_alpha() {
		return color == null ? 1. : color.a;
	}

	inline function set_alpha( v : Float ) {
		if (color == null)
			color = new h3d.Vector(1, 1, 1, v);
		else 
			color.a = v;
		return v;
	}

}

/**
	h2d.Animation is used to display a parametrized sequence of bitmap tiles on the screen.
	This is more powerful version than h2d.Anim, but requires more setup.
**/
class Animation extends Drawable {

	/**
		Create an array of frames with fixed framerate. Will produce same playback result as h2d.Anim.
	**/
	public static function fromFixedFramerate( tiles : Array<h2d.Tile>, fps : Float ) {
		var result : Array<AnimationFrame> = new Array();
		fps = 1 / fps;
		for ( tile in tiles ) {
			result.push(new AnimationFrame(tile, fps));
		}
		return result;
	}

	/**
		Create an array from list of tiles and their durations. Both arrays should be the same length.
	**/
	public static function fromDurationList( tiles : Array<h2d.Tile>, durations : Array<Float> ) {
		if ( durations.length != tiles.length ) throw "Tiles and durations length mismatch!";
		var result : Array<AnimationFrame> = new Array();
		for ( i in 0...tiles.length ) {
			result.push(new AnimationFrame(tiles[i], durations[i]));
		}
		return result;
	}

	/**
		The current animation, as a list of AnimationFrame instances to display.
	**/
	public var frames(default, null) : Array<AnimationFrame>;

	/**
		The current frame the animation is currently playing. Always in `[0,frames.length]` range
	**/
	public var currentFrame(get,set) : Int;

	/**
		Setting pause will pause the animation, preventing any automatic change to currentFrame.
	**/
	public var pause : Bool = false;

	/**
		Disabling loop will stop the animation at the last frame (default : true)
	**/
	public var loop : Bool = true;

	/**
		Playback speed multiplier for animation (default : 1)
	**/
	public var speed : Float = 1.;

	var curFrame : Int;
	var elapsedTime : Float;
	
	public var playWhenHidden:Bool = false;
	
	public var width(get, never):Int;
	public var height(get, never):Int;

	/**
		Create a new animation with the specified frames and parent object
	**/
	public function new( ?frames : Array<AnimationFrame>, ?parent : h2d.Object ) {
		super(parent);
		this.frames = frames == null ? [] : frames;
		this.curFrame = 0;
		this.elapsedTime = 0;
	}

	/**
		Change the currently playing animation and unset the pause if it was set.
	**/
	public function play( frames : Array<AnimationFrame>, atFrame = 0 ) {
		this.frames = frames == null ? [] : frames;
		currentFrame = atFrame;
		pause = false;
	}
	
	public function palyAt(frame:Int = 0) {
		pause = false;
		currentFrame = frame;
	}

	/**
		onAnimEnd is automatically called each time the animation will reach past the last frame.
		If loop is true, it is called everytime the animation loops.
		If loop is false, it is called once when the animation reachs `currentFrame == frames.length`
	**/
	public dynamic function onAnimEnd() {

	}

	/**
		Returns current AnimationFrame being played.
	**/
	public inline function getFrame() : AnimationFrame {
		return frames[curFrame];
	}

	/**
		Returns current h2d.Tile being played.
	**/
	public function getTile() : h2d.Tile {
		var frame = frames[curFrame];
		return frame != null ? frame.tile : null;
	}

	inline function get_currentFrame() {
		return curFrame;
	}

	function set_currentFrame( frame : Int ) {
		curFrame = frames.length == 0 ? 0 : frame % frames.length;
		while ( curFrame < 0 ) curFrame += frames.length;
		elapsedTime = 0;
		return curFrame;
	}
	
	inline function get_width() {
		var s = 0;
		for (f in frames) if (f.tile != null) s = hxd.Math.imax(f.tile.width, s);
		return s;
	}
	
	inline function get_height() {
		var s = 0;
		for (f in frames) if (f.tile != null) s = hxd.Math.imax(f.tile.height, s);
		return s;
	}

	override function getBoundsRec( relativeTo : Object, out : h2d.col.Bounds, forSize : Bool ) {
		super.getBoundsRec(relativeTo, out, forSize);
		var tile = getTile();
		if( tile != null ) addBounds(relativeTo, out, tile.dx, tile.dy, tile.width, tile.height);
	}

	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
		if (pause || frames.length < 2 || (!visible && !playWhenHidden)) return;

		var oldFrame : Int = curFrame;
		var newFrame : Int = oldFrame;
		var time = elapsedTime + ctx.elapsedTime * speed;
		var frame = frames[newFrame];
		while (time > frame.duration) {
			time -= frame.duration;
			newFrame++;
			if ( newFrame == frames.length ) {
				if ( loop ) {
					curFrame = newFrame - 1;
					elapsedTime = hxd.Math.EPSILON;
					onAnimEnd();
					// Callback changed current frame - cancel everything.
					if (elapsedTime == 0) {
						return;
					}
					// Callback paused playback, use last frame.
					if ( pause ) {
						elapsedTime = 0;
						return;
					} else {
						newFrame = 0;
					}
				} else {
					curFrame = newFrame - 1;
					pause = true;
					onAnimEnd();
					return;
				}
			}

			frame = frames[newFrame];
			// Prevent skipping over keyframes.
			if ( frame.isKey && time > frame.duration ) {
				time = 0;
				break;
			}
		}

		curFrame = newFrame;
		elapsedTime = time;
	}

	override function draw( ctx : RenderContext ) {
		var frame = frames[curFrame];
		if ( frame != null && frame.tile != null ) {
			var oldColor = color;
			if (frame.color != null) this.color = frame.color;
			emitTile(ctx, frame.tile);
			this.color = oldColor;
		}
	}
}