package;

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
	public static final plugins:PluginManager = new PluginManager();

	public static function main():Void {
		var args:Array<String> = Sys.args();

		var theme:String = Themes.cyber;
		for (i in 0...args.length)
			if (StringTools.startsWith(args[i], "--theme=")) {
				theme = args[i].substr("--theme=".length);
				args.splice(i, 1);
				break;
			}

		Intro.show(version, theme);

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
  aedifex create <path>
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

		var projectPath:String = Path.removeTrailingSlashes(args[1]);
		FileSystem.createDirectory(projectPath);
		FileSystem.createDirectory(Path.join([projectPath, "src"]));
		FileSystem.createDirectory(Path.join([projectPath, "bin"]));

		var mainT:String = Resource.getString("MainTemplate");
		if (mainT == null) {
			throw "Missing resource: MainTemplate";
		}

		File.saveContent(Path.join([projectPath, "src", "Main.hx"]), mainT);

		var cfgT:String = Resource.getString("AedifexConfigTemplate");
		if (cfgT == null) {
			throw "Missing resource: AedifexConfigTemplate";
		}

		var norm:String = Path.normalize(projectPath);
		var li:Int = norm.lastIndexOf("/") + 1;
		var name:String = norm.substr(li);
		var cfg:AedifexConfig = cast Json.parse(cfgT);
		cfg.config.meta.title = name;
		cfg.config.app.file = name;

		File.saveContent(Path.join([projectPath, "config.json"]), JsonPrinter.print(cfg, null, "\t"));
		Sys.println("New project created at: " + projectPath);
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
