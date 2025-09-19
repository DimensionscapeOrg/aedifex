package aedifex.util;

class ANSI {
	public static inline var ESC:String = "\x1b[";

	public static var enabled(default, null):Bool = true;
	public static var truecolor(default, null):Bool = false;
	public static var ansi256(default, null):Bool = false;
	public static var supportsLinks(default, null):Bool = false;
	public static var capability(default, null):String = "basic";
	public static var utf8Likely(default, null):Bool = true;
	private static var _forcedVT:Bool = false;
	private static var _forcedTruecolor:Bool = false;

	public static function forceVT(on:Bool, truecolor:Bool = true):Void {
		_forcedVT = on;
		_forcedTruecolor = on && truecolor;
		detect();
	}

	private static inline function vtWindows():Bool {
		return Sys.getEnv("WT_SESSION") != null || Sys.getEnv("ConEmuANSI") == "ON" || Sys.getEnv("ANSICON") != null;
	}

	public static function detect():Void {
		var sysName:String = Sys.systemName().toLowerCase();
		var noColor:Bool = Sys.getEnv("NO_COLOR") != null;

		var term:String = (Sys.getEnv("TERM") : String);
		var termL:String = term == null ? null : term.toLowerCase();
		var colorterm:String = (Sys.getEnv("COLORTERM") : String);
		var colorL:String = colorterm == null ? null : colorterm.toLowerCase();
		var termProg:String = (Sys.getEnv("TERM_PROGRAM") : String);

		var wt:Bool = Sys.getEnv("WT_SESSION") != null;
		var conEmu:Bool = Sys.getEnv("ConEmuANSI") == "ON";
		var ansicon:Bool = Sys.getEnv("ANSICON") != null;

		var looksVT:Bool = (termL != null
			&& (termL.indexOf("xterm") >= 0 || termL.indexOf("screen") >= 0 || termL.indexOf("vt") >= 0 || termL.indexOf("ansi") >= 0
				|| termL.indexOf("256color") >= 0 || termL.indexOf("truecolor") >= 0 || termL.indexOf("direct") >= 0));

		if (sysName == "windows") {
			enabled = !noColor && (wt || conEmu || ansicon || looksVT || _forcedVT);
			truecolor = enabled
				&& (wt || (colorL != null && (colorL.indexOf("truecolor") >= 0 || colorL.indexOf("24bit") >= 0)) || _forcedTruecolor);
			ansi256 = enabled && !truecolor && (looksVT || conEmu || ansicon);
			utf8Likely = enabled;
		} else {
			var isTtyOk:Bool = termL != null && termL != "" && termL != "dumb";
			enabled = !noColor && (isTtyOk || _forcedVT);
			truecolor = enabled
				&& ((colorL != null && (colorL.indexOf("truecolor") >= 0 || colorL.indexOf("24bit") >= 0))
					|| (termL != null && (termL.indexOf("direct") >= 0 || termL.indexOf("truecolor") >= 0))
					|| _forcedTruecolor);
			ansi256 = enabled && !truecolor && termL != null && termL.indexOf("256color") >= 0;
			utf8Likely = true;
		}

		supportsLinks = enabled && (termProg == "iTerm.app" || wt || (Sys.getEnv("VTE_VERSION") != null));
		capability = !enabled ? "none" : (truecolor ? "truecolor" : (ansi256 ? "ansi256" : "basic"));
	}

	public static function forceDisable():Void {
		enabled = false;
		truecolor = false;
		ansi256 = false;
		supportsLinks = false;
		capability = "none";
		utf8Likely = false;
	}

	private static function __init__() {
		detect();
	}

	public static var reset(get, never):String;
	public static var bold(get, never):String;
	public static var dim(get, never):String;
	public static var italic(get, never):String;
	public static var underline(get, never):String;
	public static var inverse(get, never):String;
	public static var strike(get, never):String;

	public static var red(get, never):String;
	public static var green(get, never):String;
	public static var yellow(get, never):String;
	public static var blue(get, never):String;
	public static var magenta(get, never):String;
	public static var cyan(get, never):String;
	public static var white(get, never):String;
	public static var brightWhite(get, never):String;

	private static inline function g(code:String):String {
		return enabled ? ESC + code : "";
	}

	private static inline function get_reset():String {
		return g("0m");
	}

	private static inline function get_bold():String {
		return g("1m");
	}

	private static inline function get_dim():String {
		return g("2m");
	}

	private static inline function get_italic():String {
		return g("3m");
	}

	private static inline function get_underline():String {
		return g("4m");
	}

	private static inline function get_inverse():String {
		return g("7m");
	}

	private static inline function get_strike():String {
		return g("9m");
	}

	private static inline function get_red():String {
		return g("31m");
	}

	private static inline function get_green():String {
		return g("32m");
	}

	private static inline function get_yellow():String {
		return g("33m");
	}

	private static inline function get_blue():String {
		return g("34m");
	}

	private static inline function get_magenta():String {
		return g("35m");
	}

	private static inline function get_cyan():String {
		return g("36m");
	}

	private static inline function get_white():String {
		return g("37m");
	}

	private static inline function get_brightWhite():String {
		return g("97m");
	}

	public static inline function fg256(code:Int):String {
		return enabled ? (ESC + "38;5;" + clamp(code, 0, 255) + "m") : "";
	}

	public static inline function bg256(code:Int):String {
		return enabled ? (ESC + "48;5;" + clamp(code, 0, 255) + "m") : "";
	}

	public static inline function rgb(r:Int, g:Int, b:Int):String {
		return enabled ? (ESC + "38;2;" + c(r) + ";" + c(g) + ";" + c(b) + "m") : "";
	}

	public static inline function bgRgb(r:Int, g:Int, b:Int):String {
		return enabled ? (ESC + "48;2;" + c(r) + ";" + c(g) + ";" + c(b) + "m") : "";
	}

	static inline function c(v:Int):Int {
		return clamp(v, 0, 255);
	}

	public static inline function fgSmart(r:Int, g:Int, b:Int):String {
		if (!enabled) {
			return "";
		}

		return switch (capability) {
			case "truecolor": rgb(r, g, b);
			case "ansi256": fg256(nearest256(r, g, b));
			case "basic": nearestBasicFG(r, g, b);
			default: "";
		}
	}

	public static inline function bgSmart(r:Int, g:Int, b:Int):String {
		if (!enabled) {
			return "";
		}

		return switch (capability) {
			case "truecolor": bgRgb(r, g, b);
			case "ansi256": ESC + "48;5;" + nearest256(r, g, b) + "m";
			case "basic": nearestBasicBG(r, g, b);
			default: "";
		}
	}

	public static inline function safe(s:String):String {
		return enabled ? s : strip(s);
	}

	public static inline function print(s:String):Void {
		Sys.print(safe(s));
	}

	public static inline function println(s:String):Void {
		print(s);
		Sys.print("\n");
	}

	public static inline function maybe(code:String):String {
		return enabled ? code : "";
	}

	public static inline function with(codes:Array<String>, s:String):String {
		return enabled ? (codes.join("") + s + reset) : s;
	}

	public static inline function colorize(s:String, codes:Array<String>):String {
		return with(codes, s);
	}

	public static inline function asciiIfNeeded(s:String, ascii:String):String {
		return utf8Likely ? s : ascii;
	}

	public static inline function visibleWidth(s:String):Int {
		return strip(s).length;
	}

	public static inline function cursorUp(n:Int):String {
		return enabled ? ESC + n + "A" : "";
	}

	public static inline function cursorDown(n:Int):String {
		return enabled ? ESC + n + "B" : "";
	}

	public static inline function cursorForward(n:Int):String {
		return enabled ? ESC + n + "C" : "";
	}

	public static inline function cursorBack(n:Int):String {
		return enabled ? ESC + n + "D" : "";
	}

	public static inline function saveCursor():String {
		return enabled ? ESC + "s" : "";
	}

	public static inline function restoreCursor():String {
		return enabled ? ESC + "u" : "";
	}

	public static inline function hideCursor():String {
		return enabled ? ESC + "?25l" : "";
	}

	public static inline function showCursor():String {
		return enabled ? ESC + "?25h" : "";
	}

	public static inline function clearLine():String {
		return enabled ? ESC + "2K" : "";
	}

	public static inline function clearToEnd():String {
		return enabled ? ESC + "K" : "";
	}

	public static inline function clearScreen():String {
		return enabled ? ESC + "2J" : "";
	}

	public static inline function link(text:String, url:String):String {
		if (!(enabled && supportsLinks)) {
			return text;
		}

		return "\x1b]8;;" + url + "\x1b\\" + text + "\x1b]8;;\x1b\\";
	}

	public static function strip(s:String):String {
		var re:EReg = new EReg("(?:\\x1b\\[[0-9;?]*[ -/]*[@-~])|(?:\\x1b\\][^\\x07\\x1b]*(?:\\x07|\\x1b\\\\))", "g");
		return re.replace(s, "");
	}

	public static function nearest256(r:Int, g:Int, b:Int):Int {
		inline function toIndex(v:Int):Int {
			return clamp(Math.round(v / 51.0), 0, 5);
		}

		inline function fromIndex(i:Int):Int {
			return clamp(Std.int(i * 51), 0, 255);
		}

		var ri:Int = toIndex(r), gi = toIndex(g), bi = toIndex(b);
		var cube:Int = 16 + 36 * ri + 6 * gi + bi;
		var cr:Int = fromIndex(ri), cg = fromIndex(gi), cb = fromIndex(bi);
		var cubeDist:Int = dist2(r, g, b, cr, cg, cb);
		var gray:Int = Std.int((r + g + b) / 3);
		var gi2:Int = clamp(Math.round((gray - 8) / 10.0), 0, 23);
		var grayCode:Int = 232 + gi2;
		var gv:Int = clamp(8 + gi2 * 10, 0, 255);
		var grayDist:Int = dist2(r, g, b, gv, gv, gv);
		return (grayDist < cubeDist) ? grayCode : cube;
	}

	private static inline function nearestBasicFG(r:Int, g:Int, b:Int):String {
		if (r > g && r > b) {
			return red;
		}

		if (g > r && g > b) {
			return green;
		}

		if (b > r && b > g) {
			return blue;
		}

		if (r == g && r > b) {
			return yellow;
		}

		if (g == b && g > r) {
			return cyan;
		}

		if (r == b && r > g) {
			return magenta;
		}

		return white;
	}

	private static inline function nearestBasicBG(r:Int, g:Int, b:Int):String {
		inline function bg(code:Int):String {
			return enabled ? ESC + (40 + code) + "m" : "";
		}

		if (r > g && r > b) {
			return bg(1);
		}

		if (g > r && g > b) {
			return bg(2);
		}

		if (b > r && b > g) {
			return bg(4);
		}

		if (r == g && r > b) {
			return bg(3);
		}

		if (g == b && g > r) {
			return bg(6);
		}

		if (r == b && r > g) {
			return bg(5);
		}

		return bg(7);
	}

	private static inline function clamp(v:Int, lo:Int, hi:Int):Int {
		return (v < lo) ? lo : ((v > hi) ? hi : v);
	}

	private static inline function dist2(r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int):Int {
		var dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
		return dr * dr + dg * dg + db * db;
	}
}
