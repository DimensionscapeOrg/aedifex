package aedifex.util;

import haxe.Resource;
import aedifex.theme.Theme;
import aedifex.theme.Themes;

class Intro {
	private static inline final CONTENT_WIDTH:Int = 61;

	public static function show(version:String, ?theme:String = "defaultTheme"):Void {
		var bannerRes = Resource.getString("AedifexBanner");
		var banner = (bannerRes != null) ? bannerRes : defaultBanner(version);

		if (ANSI.prefersRichBanner()) {
			var theme:Theme = Theme.resolveTheme(theme);
			theme.renderBanner(banner, version);
			return;
		}

		if (ANSI.prefersBannerArt()) {
			showMonochrome(banner, version);
			return;
		}

		if (!ANSI.prefersRichBanner()) {
			showPlain(version);
			return;
		}
	}

	private static function showPlain(version:String):Void {
		Sys.println("");
		Sys.println("Aedifex " + version);
		Sys.println("lightweight Haxe build tool");
		Sys.println("");
	}

	private static function showMonochrome(banner:String, version:String):Void {
		Sys.print(banner);
		Sys.println("Command-Line Tool " + version);
	}

	private static function defaultBanner(version:String):String {
		return "\n"
			+ ".................................................................\n"
			+ "||'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''||\n"
			+ "||   .d8b.  d88888b d8888b. d888888b d88888b d88888b db    db  ||\n"
			+ "||  d8' `8b 88'     88  `8D   `88'   88'     88'     `8b  d8'  ||\n"
			+ "||  88ooo88 88ooooo 88   88    88    88ooo   88ooooo  `8bd8'   ||\n"
			+ "||  88~~~88 88~~~~~ 88   88    88    88~~~   88~~~~~  .dPYb.   ||\n"
			+ "||  88   88 88.     88  .8D   .88.   88      88.     .8P  Y8.  ||\n"
			+ "||  YP   YP Y88888P Y8888D' Y888888P YP      Y88888P YP    YP  ||\n"
			+ buildDaemonLine(version) + "\n"
			+ ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n";
	}

	private static function buildDaemonLine(version:String):String {
		var daemon = "-- Build System Daemon --";
		var versionLabel = "v" + version;
		var chars = [for (_ in 0...CONTENT_WIDTH) " "];

		writeCentered(chars, daemon);
		writeRightAligned(chars, versionLabel);

		return "||" + chars.join("") + "||";
	}

	private static function repeat(value:String, count:Int):String {
		var buffer = new StringBuf();
		for (i in 0...count) {
			buffer.add(value);
		}
		return buffer.toString();
	}

	private static function writeCentered(chars:Array<String>, text:String):Void {
		var start = Std.int((CONTENT_WIDTH - text.length) / 2);
		if (start < 0) {
			start = 0;
		}
		writeAt(chars, text, start);
	}

	private static function writeRightAligned(chars:Array<String>, text:String):Void {
		var start = CONTENT_WIDTH - text.length;
		if (start < 0) {
			start = 0;
		}
		writeAt(chars, text, start);
	}

	private static function writeAt(chars:Array<String>, text:String, start:Int):Void {
		for (i in 0...text.length) {
			var index = start + i;
			if (index < 0 || index >= CONTENT_WIDTH) {
				continue;
			}
			chars[index] = text.charAt(i);
		}
	}
}
