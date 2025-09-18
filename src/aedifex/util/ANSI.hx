package aedifex.util;

class ANSI {
	public static inline var ESC:String = "\x1b[";

	public static var enabled(default, null):Bool = true;
	public static var truecolor(default, null):Bool = false;
	public static var ansi256(default, null):Bool = false;
	public static var supportsLinks(default, null):Bool = false;

	public static function detect():Void {
		final sysName = Sys.systemName().toLowerCase();
		final term = (Sys.getEnv("TERM") : String);
		final noColor = Sys.getEnv("NO_COLOR") != null;
		final wt = Sys.getEnv("WT_SESSION") != null;
		final conEmu = Sys.getEnv("ConEmuANSI") == "ON";
		final ansicon = Sys.getEnv("ANSICON") != null;
		final colorterm = (Sys.getEnv("COLORTERM") : String);
		final termProg = (Sys.getEnv("TERM_PROGRAM") : String);
		final isTtyOk = term != null && term != "" && term != "dumb";

		enabled = !noColor && (sysName != "windows" ? isTtyOk : (wt || conEmu || ansicon || isTtyOk));

		truecolor = enabled
			&& ((colorterm != null && (colorterm.indexOf("truecolor") >= 0 || colorterm.indexOf("24bit") >= 0))
				|| (term != null && (term.indexOf("direct") >= 0 || term.indexOf("truecolor") >= 0))
				|| wt);

		ansi256 = enabled
			&& (!truecolor)
			&& (term != null && (term.indexOf("256color") >= 0 || term.indexOf("screen") >= 0 || term.indexOf("xterm") >= 0));

		supportsLinks = enabled && (termProg == "iTerm.app" || wt || (Sys.getEnv("VTE_VERSION") != null));
	}

	private static function __init__()
		detect();

	public static inline var reset:String = ESC + "0m";
	public static inline var bold:String = ESC + "1m";
	public static inline var dim:String = ESC + "2m";
	public static inline var italic:String = ESC + "3m";
	public static inline var underline:String = ESC + "4m";
	public static inline var inverse:String = ESC + "7m";
	public static inline var strike:String = ESC + "9m";

	public static inline var red:String = ESC + "31m";
	public static inline var green:String = ESC + "32m";
	public static inline var yellow:String = ESC + "33m";
	public static inline var blue:String = ESC + "34m";
	public static inline var magenta:String = ESC + "35m";
	public static inline var cyan:String = ESC + "36m";
	public static inline var white:String = ESC + "37m";
	public static inline var brightWhite:String = ESC + "97m";

	public static inline function fg256(code:Int):String {
		return ESC + "38;5;" + clamp(code, 0, 255) + "m";
	}

	public static inline function bg256(code:Int):String {
		return ESC + "48;5;" + clamp(code, 0, 255) + "m";
	}

	public static inline function rgb(r:Int, g:Int, b:Int):String {
		return ESC + "38;2;" + clamp(r, 0, 255) + ";" + clamp(g, 0, 255) + ";" + clamp(b, 0, 255) + "m";
	}

	public static inline function bgRgb(r:Int, g:Int, b:Int):String {
		return ESC + "48;2;" + clamp(r, 0, 255) + ";" + clamp(g, 0, 255) + ";" + clamp(b, 0, 255) + "m";
	}

	public static inline function rgbSmart(r:Int, g:Int, b:Int):String {
		if (!enabled) {
			return "";
		}
		if (truecolor) {
			return rgb(r, g, b);
		}
		if (ansi256) {
			return fg256(nearest256(r, g, b));
		}
		return "";
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

	public static function strip(s:String):String {
		var re:EReg = new EReg("\\x1b\\[[0-9;?]*[ -/]*[@-~]", "g");
		return re.replace(s, "");
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

	public static function nearest256(r:Int, g:Int, b:Int):Int {
		inline function toIndex(v:Int):Int {
			return clamp(Math.round(v / 51.0), 0, 5);
		}
		inline function fromIndex(i:Int):Int{
			return clamp(Std.int(i * 51), 0, 255);
		}
			

		var ri = toIndex(r), gi = toIndex(g), bi = toIndex(b);
		var cubeCode = 16 + 36 * ri + 6 * gi + bi;
		var cr = fromIndex(ri), cg = fromIndex(gi), cb = fromIndex(bi);
		var cubeDist = dist2(r, g, b, cr, cg, cb);

		var gray = Std.int((r + g + b) / 3);
		var gi2 = clamp(Math.round((gray - 8) / 10.0), 0, 23);
		var grayCode = 232 + gi2;
		var gv = clamp(8 + gi2 * 10, 0, 255);
		var grayDist = dist2(r, g, b, gv, gv, gv);

		return (grayDist < cubeDist) ? grayCode : cubeCode;
	}

	static inline function clamp(v:Int, lo:Int, hi:Int):Int{
		return (v < lo) ? lo : (v > hi ? hi : v);
	}
		

	static inline function dist2(r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int):Int {
		var dr = r1 - r2;
		var dg = g1 - g2;
		var db = b1 - b2;
		return dr * dr + dg * dg + db * db;
	}
}
