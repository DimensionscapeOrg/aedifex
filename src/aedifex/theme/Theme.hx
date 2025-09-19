package aedifex.theme;

import haxe.Json;
import aedifex.util.ANSI;
import aedifex.theme.ThemeData.Stop;
import aedifex.theme.ThemeData.RGB;

@:forward
abstract Theme(ThemeData) from ThemeData to ThemeData {
	public inline function new(data:ThemeData) {
		this = data;
	}

	@:from private static function fromJson(s:String):Theme {
		return new Theme(Json.parse(s));
	}

	@:from private static function fromStruct(o:Dynamic):Theme {
		return new Theme(cast o);
	}

	public static function resolveTheme(theme:String):Theme{
        var data:String = Themes.themeRegistry.get(theme);
        return fromJson(data);
    }
		

	public function renderBanner(banner:String, version:String):Void {
		switch this.kind.toLowerCase() {
			case "flat":
				var head:RGB = this.head, sub = this.sub, meta = this.meta;
				Sys.print(ANSI.rgb(head.r, head.g, head.b) + banner + ANSI.reset);
				Sys.print(ANSI.rgb(sub.r, sub.g, sub.b) + 'Command-Line Tool ' + version + ANSI.reset + "\n");
				Sys.println(ANSI.rgb(meta.r, meta.g, meta.b) + '(c)2020-2025 Dimensionscape LLC. All rights reserved.' + ANSI.reset);

			case "sweep":
				printSweep(banner, this.sweep.s, this.sweep.e);
				Sys.println('Command-Line Tool ' + version);

			case "multi":
				printMulti(banner, this.stops);
				Sys.println('Command-Line Tool ' + version);

			case "rainbow":
				printRainbow(banner);
				Sys.println('Command-Line Tool ' + version);

			default:
				Sys.println(banner);
		}
	}

	private static function printSweep(banner:String, s:RGB, e:RGB):Void {
		for (line in banner.split("\n")) {
			if (line.length == 0) {
				Sys.println("");
				continue;
			}
			Sys.println(gradientLine(line, s, e));
		}
	}

	private static function printMulti(banner:String, stops:Array<Stop>):Void {
		for (line in banner.split("\n")) {
			if (line.length == 0) {
				Sys.println("");
				continue;
			}
			Sys.println(gradientLineMulti(line, stops));
		}
	}

	private static function printRainbow(banner:String):Void {
		var cols:Array<String> = [
			ANSI.rgb(255, 80, 80),
			ANSI.rgb(255, 180, 60),
			ANSI.rgb(255, 255, 80),
			ANSI.rgb(80, 255, 120),
			ANSI.rgb(80, 180, 255),
			ANSI.rgb(200, 80, 255)
		];
		for (line in banner.split("\n")) {
			if (line.length == 0) {
				Sys.println("");
				continue;
			}
			var out:String = "";
			for (i in 0...line.length){
                out += cols[i % cols.length] + line.charAt(i);
            }
				
			Sys.println(out + ANSI.reset);
		}
	}

	private static function gradientLine(s:String, sRGB:RGB, eRGB:RGB):String {
		var out:String = "";
		var n:Int = s.length;
		for (i in 0...n) {
			var t:Float = (n <= 1) ? 0.0 : i / (n - 1);
			var r:Int = Std.int(sRGB.r + (eRGB.r - sRGB.r) * t);
			var g:Int = Std.int(sRGB.g + (eRGB.g - sRGB.g) * t);
			var b:Int = Std.int(sRGB.b + (eRGB.b - sRGB.b) * t);
			out += ANSI.rgb(r, g, b) + s.charAt(i);
		}
		return out + ANSI.reset;
	}

	static function gradientLineMulti(s:String, stops:Array<Stop>):String {
		if (stops == null || stops.length == 0){
            return s;
        }
			
		var out:String = "";
		var n:Int = s.length;
		for (i in 0...n) {
			var p:Float = (n <= 1) ? 0.0 : i / (n - 1);
			var k:Int = 0;
			while (k + 1 < stops.length && p > stops[k + 1].pos){
                k++;
            }
				
			var a:Stop = stops[k];
			var b:Stop = stops[Std.int(Math.min(k + 1, stops.length - 1))];
			var span:Float = (b.pos - a.pos);
			var t:Float = (span <= 0) ? 0.0 : (p - a.pos) / span;
			var r:Int = Std.int(a.r + (b.r - a.r) * t);
			var g:Int = Std.int(a.g + (b.g - a.g) * t);
			var bl:Int = Std.int(a.b + (b.b - a.b) * t);
			out += ANSI.rgb(r, g, bl) + s.charAt(i);
		}
		return out + ANSI.reset;
	}
}
