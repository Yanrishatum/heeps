// Disclaimer: This is a straight copy-paste of HaxePunk Ease class, because I got tired of constantly going to that class each time I use easers in my Heaps projects.
package hxd;

/**
 * Static class with useful easer functions that can be used by Tweens.
 */
@:keep
class Ease
{

	/** Sine in. */
	public static function sineIn(t:Float):Float
	{
		return -Math.cos(PI2 * t) + 1;
	}

	/** Sine out. */
	public static function sineOut(t:Float):Float
	{
		return Math.sin(PI2 * t);
	}

	/** Sine in and out. */
	public static function sineInOut(t:Float):Float
	{
		return -Math.cos(PI * t) / 2 + .5;
	}
	
	/** Quadratic in. */
	public static function quadIn(t:Float):Float
	{
		return t * t;
	}

	/** Quadratic out. */
	public static function quadOut(t:Float):Float
	{
		return -t * (t - 2);
	}

	/** Quadratic in and out. */
	public static function quadInOut(t:Float):Float
	{
		return t <= .5 ? t * t * 2 : 1 - (--t) * t * 2;
	}

	/** Cubic in. */
	public static function cubeIn(t:Float):Float
	{
		return t * t * t;
	}

	/** Cubic out. */
	public static function cubeOut(t:Float):Float
	{
		return 1 + (--t) * t * t;
	}

	/** Cubic in and out. */
	public static function cubeInOut(t:Float):Float
	{
		return t <= .5 ? t * t * t * 4 : 1 + (--t) * t * t * 4;
	}

	/** Quart in. */
	public static function quartIn(t:Float):Float
	{
		return t * t * t * t;
	}

	/** Quart out. */
	public static function quartOut(t:Float):Float
	{
		return 1 - (t-=1) * t * t * t;
	}

	/** Quart in and out. */
	public static function quartInOut(t:Float):Float
	{
		return t <= .5 ? t * t * t * t * 8 : (1 - (t = t * 2 - 2) * t * t * t) / 2 + .5;
	}

	/** Quint in. */
	public static function quintIn(t:Float):Float
	{
		return t * t * t * t * t;
	}

	/** Quint out. */
	public static function quintOut(t:Float):Float
	{
		return (t = t - 1) * t * t * t * t + 1;
	}

	/** Quint in and out. */
	public static function quintInOut(t:Float):Float
	{
		return ((t *= 2) < 1) ? (t * t * t * t * t) / 2 : ((t -= 2) * t * t * t * t + 2) / 2;
	}

	/** Exponential in. */
	public static function expoIn(t:Float):Float
	{
		return Math.pow(2, 10 * (t - 1));
	}

	/** Exponential out. */
	public static function expoOut(t:Float):Float
	{
		return -Math.pow(2, -10 * t) + 1;
	}

	/** Exponential in and out. */
	public static function expoInOut(t:Float):Float
	{
		return t < .5 ? Math.pow(2, 10 * (t * 2 - 1)) / 2 : (-Math.pow(2, -10 * (t * 2 - 1)) + 2) / 2;
	}

	/** Circle in. */
	public static function circIn(t:Float):Float
	{
		return -(Math.sqrt(1 - t * t) - 1);
	}

	/** Circle out. */
	public static function circOut(t:Float):Float
	{
		return Math.sqrt(1 - (t - 1) * (t - 1));
	}

	/** Circle in and out. */
	public static function circInOut(t:Float):Float
	{
		return t <= .5 ? (Math.sqrt(1 - t * t * 4) - 1) / -2 : (Math.sqrt(1 - (t * 2 - 2) * (t * 2 - 2)) + 1) / 2;
	}

	/** Back in. */
	public static function backIn(t:Float):Float
	{
		return t * t * (2.70158 * t - 1.70158);
	}

	/** Back out. */
	public static function backOut(t:Float):Float
	{
		return 1 - (--t) * (t) * (-2.70158 * t - 1.70158);
	}

	/** Back in and out. */
	public static function backInOut(t:Float):Float
	{
		t *= 2;
		if (t < 1) return t * t * (2.70158 * t - 1.70158) / 2;
		t --;
		return (1 - (--t) * (t) * (-2.70158 * t - 1.70158)) / 2 + .5;
	}

	// elastic

	/** Bounce in. */
	public static function bounceIn(t:Float):Float
	{
		t = 1 - t;
		if (t < B1) return 1 - 7.5625 * t * t;
		if (t < B2) return 1 - (7.5625 * (t - B3) * (t - B3) + .75);
		if (t < B4) return 1 - (7.5625 * (t - B5) * (t - B5) + .9375);
		return 1 - (7.5625 * (t - B6) * (t - B6) + .984375);
	}

	/** Bounce out. */
	public static function bounceOut(t:Float):Float
	{
		if (t < B1) return 7.5625 * t * t;
		if (t < B2) return 7.5625 * (t - B3) * (t - B3) + .75;
		if (t < B4) return 7.5625 * (t - B5) * (t - B5) + .9375;
		return 7.5625 * (t - B6) * (t - B6) + .984375;
	}

	/** Bounce in and out. */
	public static function bounceInOut(t:Float):Float
	{
		if (t < .5)
		{
			t = 1 - t * 2;
			if (t < B1) return (1 - 7.5625 * t * t) / 2;
			if (t < B2) return (1 - (7.5625 * (t - B3) * (t - B3) + .75)) / 2;
			if (t < B4) return (1 - (7.5625 * (t - B5) * (t - B5) + .9375)) / 2;
			return (1 - (7.5625 * (t - B6) * (t - B6) + .984375)) / 2;
		}
		t = t * 2 - 1;
		if (t < B1) return (7.5625 * t * t) / 2 + .5;
		if (t < B2) return (7.5625 * (t - B3) * (t - B3) + .75) / 2 + .5;
		if (t < B4) return (7.5625 * (t - B5) * (t - B5) + .9375) / 2 + .5;
		return (7.5625 * (t - B6) * (t - B6) + .984375) / 2 + .5;
	}

	// Easing constants.
	private static var PI(get,never):Float;
	private static var PI2(get,never):Float;
	private static var EL(get,never):Float;
	private static inline var B1:Float = 1 / 2.75;
	private static inline var B2:Float = 2 / 2.75;
	private static inline var B3:Float = 1.5 / 2.75;
	private static inline var B4:Float = 2.5 / 2.75;
	private static inline var B5:Float = 2.25 / 2.75;
	private static inline var B6:Float = 2.625 / 2.75;
	private static inline function get_PI(): Float  { return Math.PI; }
	private static inline function get_PI2(): Float { return Math.PI / 2; }
	private static inline function get_EL(): Float  { return 2 * PI / 0.45; }

	/**
	 * Operation of in/out easers:
	 *
	 * in(t)
	 *		return t;
	 * out(t)
	 * 		return 1 - in(1 - t);
	 * inOut(t)
	 * 		return (t <= .5) ? in(t * 2) / 2 : out(t * 2 - 1) / 2 + .5;
	 */
}

class EaseElastic
{
	
	// final magnitude:Float;
	// final period:Float;
	
	// public function new(period:Float = .3)
	// {
	// 	this.magnitude = Math.asin(1);
	// 	this.period = period;
	// }
	
	// function easeIn(t:Float):Float
	// {
	// 	// b = 0, c = 1, d = 1
	// 	if (t == 0) return 0;
		
	// 	return t;
	// }
	// easeInElastic: function (x, t, b, c, d) {
	// 	var s=1.70158;var p=0;var a=c;
	// 	if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
	// 	if (a < Math.abs(c)) { a=c; var s=p/4; }
	// 	else var s = p/(2*Math.PI) * Math.asin (c/a);
	// 	return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
	// },
	// easeOutElastic: function (x, t, b, c, d) {
	// 	var s=1.70158;var p=0;var a=c;
	// 	if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
	// 	if (a < Math.abs(c)) { a=c; var s=p/4; }
	// 	else var s = p/(2*Math.PI) * Math.asin (c/a);
	// 	return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
	// },
	// easeInOutElastic: function (x, t, b, c, d) {
	// 	var s=1.70158;var p=0;var a=c;
	// 	if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
	// 	if (a < Math.abs(c)) { a=c; var s=p/4; }
	// 	else var s = p/(2*Math.PI) * Math.asin (c/a);
	// 	if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
	// 	return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;
	// },
}

class EaseBack
{
	
	static var cache:Array<EaseBack> = new Array();
	public static function get(magnitude:Float = 1.70158):EaseBack
	{
		for (c in cache)
		{
			if (c.magnitude == magnitude) return c;
		}
		var c = new EaseBack(magnitude);
		cache.push(c);
		return c;
	}
	
	final magnitude:Float;
	final magnitude2:Float;
	
	function new(magnitude:Float)
	{
		this.magnitude = magnitude;
		magnitude2 = magnitude + 1;
	}
	
	/** Back in. */
	function easeIn(t:Float):Float
	{
		return t * t * (magnitude2 * t - magnitude);
	}

	/** Back out. */
	function easeOut(t:Float):Float
	{
		return 1 - (--t) * (t) * (-magnitude2 * t - magnitude);
	}

	/** Back in and out. */
	function easeInOut(t:Float):Float
	{
		t *= 2;
		if (t < 1) return t * t * (magnitude2 * t - magnitude) / 2;
		t --;
		return (1 - (--t) * (t) * (-magnitude2 * t - magnitude)) / 2 + .5;
	}
	
}