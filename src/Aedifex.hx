package;

import aedifex.util.ANSI;
import aedifex.theme.Themes;
import aedifex.plugin.PluginManager;
import aedifex.util.Intro;
import aedifex.config.Loader;
import aedifex.config.AedifexConfig;
import aedifex.core.Target;
import aedifex.core.Builder;
import aedifex.core.Runner;
import haxe.Json;
import haxe.Resource;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

class Aedifex {
	public static inline final version:String = "0.1.0";
	public static var plugins:PluginManager;

	private static var currentTheme:String;

	public static function main():Void {
		var args:Array<String> = Sys.args();

		#if cpp
		ANSI.forceVT(true);
		ConsoleMode.enable();
		#end

		currentTheme = "cyber";

		plugins = new PluginManager();
		
		for (i in 0...args.length) {
			if (StringTools.startsWith(args[i], "--theme=")) {
				var themeName:String = args[i].substr("--theme=".length);
				if(Themes.themeRegistry.exists(themeName)){
					currentTheme = themeName;
				}
				args.splice(i, 1);
				break;
			}
		}

		Intro.show(version, currentTheme);

		if (args.length == 0) {
			return help();
		}

		var cmd:String = args[0].toLowerCase();
		try {
			switch cmd {
				case "build":
					doBuild(args);
				case "run":
					doRun(args);
				case "test":
					doTest(args);
				case "create":
					doCreate(args);
				case "help", "-h", "--help":
					help();
				default:
					help('Unknown command: $cmd');
			}
		} catch (e) {
			Sys.println('[Aedifex] ' + Std.string(e));
			Sys.exit(1);
		}
	}

	private static function help(?msg:String):Void {
		if (msg != null) {
			Sys.println(msg);
		}

		Sys.println("
Aedifex: A Tiny cross-target build system daemon

Usage:
  aedifex create <path> --plugin
  aedifex build <target> <projectPath> [--debug] [--define KEY[=VAL]]... [--lib LIB]...
  aedifex run   <target> <projectPath>
  aedifex test  <target> <projectPath> [--debug]

Targets: cpp | hl | neko | java | jvm
");
	}

	private static function doCreate(args:Array<String>):Void {
		if (args.length < 2) {
			throw "create requires <path>";
		}

		var isPlugin:Bool = false;
		for (i in 2...args.length) {
			var a:String = args[i];
			if (a == "--plugin" || a == "-p") {
				isPlugin = true;
			}
		}

		var projectPath:String = Path.removeTrailingSlashes(args[1]);
		var norm:String = Path.normalize(projectPath);
		var li:Int = norm.lastIndexOf("/") + 1;
		var name:String = norm.substr(li);

		ensureDir(projectPath);
		ensureDir(Path.join([projectPath, "src"]));
		ensureDir(Path.join([projectPath, "bin"]));

		if (isPlugin) {
			var pluginDir:String = Path.join([projectPath, "src", "aedifex", "plugin"]);
			ensureDir(Path.join([projectPath, "src", "aedifex"]));
			ensureDir(pluginDir);

			var wireSrc:String = Resource.getString("PluginWire");
			if (wireSrc == null) {
				throw "Missing resource: PluginWire";
			}

			File.saveContent(Path.join([pluginDir, "PluginWire.hx"]), wireSrc);

			Sys.println("New plugin project created at: " + projectPath);
		}

		var mainT:String = Resource.getString("main-template");
		if (mainT == null) {
			throw "Missing resource: main-template";
		}

		File.saveContent(Path.join([projectPath, "src", "Main.hx"]), mainT);

		var cfgT:String = Resource.getString("config-template");
		if (cfgT == null) {
			throw "Missing resource: config-template";
		}

		var cfg:AedifexConfig = cast Json.parse(cfgT);
		cfg.config.meta.title = name;
		cfg.config.app.file = name;

		File.saveContent(Path.join([projectPath, "config.json"]), JsonPrinter.print(cfg, null, "\t"));
		Sys.println("New project created at: " + projectPath);
	}

	private static inline function ensureDir(p:String):Void {
		if (!FileSystem.exists(p)) {
			FileSystem.createDirectory(p);
		}
	}

	private static function doBuild(args:Array<String>):Void {
		if (args.length < 3) {
			throw "build requires <target> <projectPath>";
		}
		var tgt:Target = args[1];
		var projectPath:String = Path.removeTrailingSlashes(args[2]);
		var cfg:AedifexConfig = Loader.load(Path.join([projectPath, "config.json"]));

		var debug:Bool = false;
		var extraDefs:Array<String> = [];
		var extraLibs:Array<String> = [];

		var i:Int = 3;

		while (i < args.length) {
			var a:String = args[i];
			switch a {
				case "--debug":
					debug = true;
				case "--define":
					if (i + 1 >= args.length) {
						throw "--define requires KEY or KEY=VAL";
					}
					extraDefs.push(args[++i]);
				case "--lib":
					if (i + 1 >= args.length) {
						throw "--lib requires LIB";
					}
					extraLibs.push(args[++i]);
				default:
					throw 'Unknown flag: $a';
			}
			i++;
		}

		Builder.build(cfg, tgt, projectPath, debug, extraDefs, extraLibs);
		Sys.println("Build complete.");
	}

	private static function doRun(args:Array<String>):Void {
		if (args.length < 3) {
			throw "run requires <target> <projectPath>";
		}
		var tgt:Target = args[1];
		var projectPath:String = Path.removeTrailingSlashes(args[2]);
		var cfg:AedifexConfig = Loader.load(Path.join([projectPath, "config.json"]));
		Runner.run(cfg, tgt, projectPath);
	}

	private static function doTest(args:Array<String>):Void {
		doBuild(args);
		doRun(args);
	}
}

@:cppInclude("Windows.h")
class ConsoleMode {
	public static function enable():Void {
		#if cpp
		untyped __cpp__('
      #ifdef _WIN32
      #ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
      #define ENABLE_VIRTUAL_TERMINAL_PROCESSING 0x0004
      #endif

      SetConsoleOutputCP(65001);
      SetConsoleCP(65001);

      DWORD m=0; HANDLE h=GetStdHandle(STD_OUTPUT_HANDLE);
      if (h!=INVALID_HANDLE_VALUE && GetConsoleMode(h,&m)) {
        m |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        SetConsoleMode(h,m);
      }
      h=GetStdHandle(STD_ERROR_HANDLE);
      if (h!=INVALID_HANDLE_VALUE && GetConsoleMode(h,&m)) {
        m |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        SetConsoleMode(h,m);
      }
      #endif
    ');
		#end
	}
}
