package aedifex.util;

import haxe.Resource;
import aedifex.util.ANSI;

class Intro {
	public static function show(version:String, ?noColor:Bool = false, ?theme:String = "red"):Void {
		if (Sys.getEnv("NO_COLOR") != null) {
			noColor = true;
		}
		var supports:Bool = supportsANSI();

		var bannerRes:String = Resource.getString("AedifexBanner");
		var banner:String = (bannerRes != null) ? bannerRes : defaultBanner();

		if (noColor || !supports) {
			Sys.println(banner);
			Sys.println('Command-Line Tool ' + version);
			Sys.println('(c) 2020-2025 Dimensionscape LLC. All rights reserved.');
			return;
		}

		var t:String = (theme == null) ? "red" : theme.toLowerCase();

		if (t == "rainbow") {
			printRainbowBanner(banner);
			printSub(version, ANSI.brightWhite, ANSI.rgb(160, 160, 160));
			return;
		}

		var sweep = sweepThemes.get(t);
		if (sweep != null) {
			printSweepBanner(banner, sweep.sR, sweep.sG, sweep.sB, sweep.eR, sweep.eG, sweep.eB);
			printSub(version, ANSI.brightWhite, ANSI.rgb(160, 160, 160));
			return;
		}

		var multi = multistopThemes.get(t);
		if (multi != null) {
			printMultistopBanner(banner, multi);
			printSub(version, ANSI.brightWhite, ANSI.rgb(160, 160, 160));
			return;
		}

		var pal = palette(t);
		Sys.print(pal.head + ANSI.bold + banner + ANSI.reset);
		Sys.print(pal.sub + ANSI.bold + 'Command-Line Tool ' + version + ANSI.reset + "\n");
		Sys.println(pal.meta + '(c) 2020-2025 Dimensionscape LLC. All rights reserved.' + ANSI.reset);
	}

	private static function palette(theme:String):{head:String, sub:String, meta:String} {
		return switch (theme) {
			case "red": {head: ANSI.red, sub: ANSI.brightWhite, meta: ANSI.dim + ANSI.white};
			case "matrix": {head: ANSI.rgb(120, 255, 120), sub: ANSI.brightWhite, meta: ANSI.rgb(120, 160, 120)};
			case "royal": {head: ANSI.rgb(140, 120, 255), sub: ANSI.brightWhite, meta: ANSI.rgb(180, 180, 200)};
			case "hacker": {head: ANSI.rgb(0, 230, 0), sub: ANSI.brightWhite, meta: ANSI.rgb(100, 140, 100)};
			case "amber": {head: ANSI.rgb(255, 191, 0), sub: ANSI.brightWhite, meta: ANSI.rgb(220, 160, 0)};
			case "crimson": {head: ANSI.rgb(220, 40, 70), sub: ANSI.brightWhite, meta: ANSI.rgb(160, 80, 90)};
			case "mono": {head: ANSI.white, sub: ANSI.brightWhite, meta: ANSI.dim + ANSI.white};
			default: {head: ANSI.red, sub: ANSI.brightWhite, meta: ANSI.dim + ANSI.white};
		}
	}

	private static var sweepThemes:Map<String, {
		sR:Int,
		sG:Int,
		sB:Int,
		eR:Int,
		eG:Int,
		eB:Int
	}> = {
		var m = new Map<String, {
			sR:Int,
			sG:Int,
			sB:Int,
			eR:Int,
			eG:Int,
			eB:Int
		}>();
		m.set("cyber", {
			sR: 180,
			sG: 0,
			sB: 255,
			eR: 0,
			eG: 255,
			eB: 220
		});
		m.set("fire", {
			sR: 255,
			sG: 120,
			sB: 0,
			eR: 200,
			eG: 20,
			eB: 0
		});
		m.set("ocean", {
			sR: 0,
			sG: 120,
			sB: 255,
			eR: 0,
			eG: 255,
			eB: 200
		});
		m.set("sunset", {
			sR: 255,
			sG: 64,
			sB: 160,
			eR: 255,
			eG: 160,
			eB: 64
		});
		m.set("emerald", {
			sR: 0,
			sG: 200,
			sB: 120,
			eR: 120,
			eG: 255,
			eB: 120
		});
		m.set("royale", {
			sR: 100,
			sG: 80,
			sB: 255,
			eR: 180,
			eG: 120,
			eB: 255
		});
		m;
	}

	private static var multistopThemes:Map<String, Array<{
		pos:Float,
		r:Int,
		g:Int,
		b:Int
	}>> = {
		var m = new Map<String, Array<{
			pos:Float,
			r:Int,
			g:Int,
			b:Int
		}>>();
		m.set("aurora", [
			{
				pos: 0.00,
				r: 20,
				g: 40,
				b: 120
			},
			{
				pos: 0.30,
				r: 0,
				g: 255,
				b: 160
			},
			{
				pos: 0.60,
				r: 100,
				g: 120,
				b: 255
			},
			{
				pos: 1.00,
				r: 0,
				g: 220,
				b: 180
			}
		]);
		m.set("vaporwave2", [
			{
				pos: 0.00,
				r: 255,
				g: 80,
				b: 160
			},
			{
				pos: 0.50,
				r: 0,
				g: 220,
				b: 200
			},
			{
				pos: 1.00,
				r: 200,
				g: 160,
				b: 255
			}
		]);
		m.set("pumpkin", [
			{
				pos: 0.00,
				r: 255,
				g: 140,
				b: 0
			},
			{
				pos: 0.50,
				r: 140,
				g: 60,
				b: 180
			},
			{
				pos: 1.00,
				r: 255,
				g: 140,
				b: 0
			}
		]);
		m;
	}

	static inline function printSub(version:String, sub:String, meta:String) {
		Sys.print(sub + ANSI.bold + 'Command-Line Tool ' + version + ANSI.reset + "\n");
		Sys.println(meta + '(c) 2020-2025 Dimensionscape LLC. All rights reserved.' + ANSI.reset);
	}

	static function printSweepBanner(banner:String, sR:Int, sG:Int, sB:Int, eR:Int, eG:Int, eB:Int):Void {
		for (line in banner.split("\n")) {
			if (line.length == 0) {
				Sys.print("\n");
				continue;
			}
			Sys.println(gradientLine(line, sR, sG, sB, eR, eG, eB));
		}
	}

	static function printMultistopBanner(banner:String, stops:Array<{
		pos:Float,
		r:Int,
		g:Int,
		b:Int
	}>):Void {
		for (line in banner.split("\n")) {
			if (line.length == 0) {
				Sys.print("\n");
				continue;
			}
			Sys.println(gradientLineMulti(line, stops));
		}
	}

	private static function printRainbowBanner(banner:String):Void {
		var cols:Array<String> = [
			ANSI.rgb(255, 80, 80), // red
			ANSI.rgb(255, 180, 60), // orange
			ANSI.rgb(255, 255, 80), // yellow
			ANSI.rgb(80, 255, 120), // green
			ANSI.rgb(80, 180, 255), // blue
			ANSI.rgb(200, 80, 255) // violet
		];
		for (line in banner.split("\n")) {
			if (line.length == 0) {
				Sys.print("\n");
				continue;
			}
			var out:String = "";
			for (i in 0...line.length) {
				out += cols[i % cols.length] + line.charAt(i);
			}

			Sys.println(out + ANSI.reset);
		}
	}

	private static function supportsANSI():Bool {
		var term:String = Sys.getEnv("TERM");
		if (term != null && term != "" && term != "dumb") {
			return true;
		}
		if (Sys.getEnv("WT_SESSION") != null) {
			return true;
		}
		if (Sys.getEnv("ConEmuANSI") == "ON") {
			return true;
		}
		if (Sys.getEnv("ANSICON") != null) {
			return true;
		}

		return true;
	}

	static inline function defaultBanner():String {
		return "
 .d8b.  d88888b d8888b. d888888b d88888b d88888b db    db 
d8' `8b 88'     88  `8D   `88'   88'     88'     `8b  d8' 
88ooo88 88ooooo 88   88    88    88ooo   88ooooo  `8bd8'  
88~~~88 88~~~~~ 88   88    88    88~~~   88~~~~~  .dPYb.  
88   88 88.     88  .8D   .88.   88      88.     .8P  Y8. 
YP   YP Y88888P Y8888D' Y888888P YP      Y88888P YP    YP 
               -- Build System Daemon --
 ";
	}

	private static inline function gradientLine(s:String, r0:Int, g0:Int, b0:Int, r1:Int, g1:Int, b1:Int):String {
		var n:Int = s.length;
		var out:String = "";
		for (i in 0...n) {
			var t:Float = (n <= 1) ? 0.0 : i / (n - 1);
			var r:Int = Std.int(r0 + (r1 - r0) * t);
			var g:Int = Std.int(g0 + (g1 - g0) * t);
			var b:Int = Std.int(b0 + (b1 - b0) * t);
			out += ANSI.rgb(r, g, b) + s.charAt(i);
		}
		return out + ANSI.reset;
	}

	private static function gradientLineMulti(s:String, stops:Array<{
		pos:Float,
		r:Int,
		g:Int,
		b:Int
	}>):String {
		if (stops == null || stops.length == 0) {
			return s;
		}
		stops.sort((a, b) -> a.pos < b.pos ? -1 : (a.pos > b.pos ? 1 : 0));
		if (stops[0].pos > 0) {
			stops.unshift({
				pos: 0.0,
				r: stops[0].r,
				g: stops[0].g,
				b: stops[0].b
			});
		}
		if (stops[stops.length - 1].pos < 1) {
			var last = stops[stops.length - 1];
			stops.push({
				pos: 1.0,
				r: last.r,
				g: last.g,
				b: last.b
			});
		}
		var out:String = "";
		var n:Int = s.length;

		for (i in 0...n) {
			var p:Float = (n <= 1) ? 0.0 : i / (n - 1);
			var k:Int = 0;
			while (k + 1 < stops.length && p > stops[k + 1].pos)
				k++;
			var a = stops[k];
			var b = stops[Std.int(Math.min(k + 1, stops.length - 1))];
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
