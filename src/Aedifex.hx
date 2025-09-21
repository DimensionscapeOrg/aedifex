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
	private static inline final USER_CFG_DIR = ".aedifex";
	private static inline final USER_CFG_FILE = "config.json";

	public static function main():Void {
		var args:Array<String> = Sys.args();

		#if cpp
		ANSI.forceVT(true);
		ConsoleMode.enable();
		#end

		currentTheme = "cyber";

		for (i in 0...args.length) {
			if (StringTools.startsWith(args[i], "--theme=")) {
				var themeName:String = args[i].substr("--theme=".length);
				if (Themes.themeRegistry.exists(themeName)) {
					currentTheme = themeName;
				}

				args.splice(i, 1);
				break;
			}
		}

		var pluginsRoot:String = resolvePluginsPath(args);
		plugins = new PluginManager(pluginsRoot);

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
				case "plugins":
					doPlugins(args, pluginsRoot); // ← new
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

	private static function doPlugins(args:Array<String>, currentRoot:String):Void {
		// Usage:
		//   aedifex plugins list
		//   aedifex plugins path
		//   aedifex plugins path --set <dir>

		if (args.length < 2) {
			Sys.println("plugins commands: list | path [--set <dir>]");
			return;
		}

		switch (args[1]) {
			case "list":
				var names:Array<String> = plugins.listNames();
				if (names.length == 0) {
					Sys.println("(no plugins found in: " + currentRoot + ")");
				} else {
					Sys.println("Plugins in " + currentRoot + ":");
					for (n in names) {
						Sys.println("  - " + n);
					}
				}

			case "path":
				var setTo:Null<String> = null;
				var i:Int = 2;
				while (i < args.length) {
					var a:String = args[i];
					if (a == "--set") {
						if (i + 1 >= args.length){
							throw "--set requires <dir>";
						}
							
						setTo = Path.normalize(args[i + 1]);
						i++;
					} else
						throw 'Unknown flag: $a';
					i++;
				}
				if (setTo == null) {
					Sys.println(currentRoot);
				} else {
					if (!sys.FileSystem.exists(setTo)){
						sys.FileSystem.createDirectory(setTo);
					}						
					saveUserPluginsPath(setTo);
					Sys.println("Plugins path set to: " + setTo);
				}

			default:
				Sys.println("plugins commands: list | path [--set <dir>]");
		}
	}

	private static function programDir():String {
		return Path.directory(Sys.programPath());
	}

	private static function userConfigPath():String {
		var home:String = Sys.getEnv(#if windows "USERPROFILE" #else "HOME" #end);
		if (home == null || home == "") {
			return null;
		}

		return Path.join([home, USER_CFG_DIR, USER_CFG_FILE]);
	}

	private static function loadUserPluginsPath():Null<String> {
		var path:String = userConfigPath();
		if (path == null || !sys.FileSystem.exists(path)) {
			return null;
		}
		try {
			var obj:Dynamic = Json.parse(sys.io.File.getContent(path));
			return (obj != null && Reflect.hasField(obj, "pluginsPath")) ? obj.pluginsPath : null;
		} catch (_:Dynamic) {
			return null;
		}
	}

	private static function saveUserPluginsPath(dir:String):Void {
		var cfgPath:String = userConfigPath();
		if (cfgPath == null) {
			return;
		}
		var cfgDir:String = Path.directory(cfgPath);
		if (!sys.FileSystem.exists(cfgDir)) {
			sys.FileSystem.createDirectory(cfgDir);
		}
		var obj:Dynamic = {};

		if (sys.FileSystem.exists(cfgPath)) {
			try {
				obj = haxe.Json.parse(sys.io.File.getContent(cfgPath));
			} catch (_:Dynamic)
				obj = {};
		}
		Reflect.setField(obj, "pluginsPath", dir);
		File.saveContent(cfgPath, haxe.format.JsonPrinter.print(obj, null, "\t"));
	}

	private static function resolvePluginsPath(argv:Array<String>):String {
		for (a in argv)
			if (StringTools.startsWith(a, "--plugins=")) {
				var p:String = a.substr("--plugins=".length);
				if (p != "") {
					return Path.normalize(p);
				}
			}
		var env:String = Sys.getEnv("AEDIFEX_PLUGINS");
		if (env != null && env != "") {
			return Path.normalize(env);
		}

		var user:String = loadUserPluginsPath();
		if (user != null && user != "") {
			return Path.normalize(user);
		}

		return Path.join([programDir(), "plugins"]);
	}

	private static function help(?msg:String):Void {
		if (msg != null) {
			Sys.println(msg);
		}

		Sys.println("
Aedifex: A Tiny cross-target build system daemon

Usage:
  aedifex create <path> [--plugin]
  aedifex build <target> <projectPath> [--debug] [--define KEY[=VAL]]... [--lib LIB]... [--plugins=<dir>]
  aedifex run   <target> <projectPath> [--plugins=<dir>]
  aedifex test  <target> <projectPath> [--debug] [--plugins=<dir>]
  aedifex plugins list
  aedifex plugins path [--set <dir>]

Global flags:
  --theme=<name>     Select banner theme
  --plugins=<dir>    Override plugin root for this invocation

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
