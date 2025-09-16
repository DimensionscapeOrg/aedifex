package aedifex.util;

class ANSI {
	public static inline var ESC:String = "\x1b[";

	public static inline var reset:String = ESC + "0m";
	public static inline var bold:String = ESC + "1m";
	public static inline var dim:String = ESC + "2m";

	public static inline var red:String = ESC + "31m";
	public static inline var green:String = ESC + "32m";
	public static inline var yellow:String = ESC + "33m";
	public static inline var blue:String = ESC + "34m";
	public static inline var magenta:String = ESC + "35m";
	public static inline var cyan:String = ESC + "36m";
	public static inline var white:String = ESC + "37m";
	public static inline var brightWhite:String = ESC + "97m";

	public static inline function fg256(code:Int):String {
		return ESC + "38;5;" + code + "m";
	}

	public static inline function bg256(code:Int):String {
		return ESC + "48;5;" + code + "m";
	}

	public static inline function rgb(r:Int, g:Int, b:Int):String {
		return ESC + "38;2;" + r + ";" + g + ";" + b + "m";
	}

	public static inline function bgRgb(r:Int, g:Int, b:Int):String {
		return ESC + "48;2;" + r + ";" + g + ";" + b + "m";
	}
}
