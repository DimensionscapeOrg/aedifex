package aedifex.core;

import aedifex.config.AedifexConfig;
import aedifex.util.SystemUtil;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class Builder {
	public static function build(cfg:AedifexConfig, tgt:Target, projectRoot:String, debug:Bool, extraDefs:Array<String>, extraLibs:Array<String>):Void {
		var conf = cfg.config;
		var src:String = Path.join([projectRoot, conf.source.path]);
		var outRoot:String = Path.join([projectRoot, conf.app.path, getTargetDir(tgt)]);
		var objDir:String = Path.join([outRoot, "obj"]);
		var hxDir:String = Path.join([outRoot, "haxe"]);
		ensureDir(objDir);
		ensureDir(hxDir);

		ProgramWriter.ensure(hxDir, conf.app.main);

		var cmd:Command = new Command();
		cmd.add("haxe");
		cmd.add("-cp");
		cmd.add(src);
		cmd.add("-cp");
		cmd.add(hxDir);
		cmd.add("-main");
		cmd.add("ProgramMain");

		for (lib in conf.haxelib) {
			cmd.add("-lib");
			cmd.add(lib);
		}

		for (lib in extraLibs) {
			cmd.add("-lib");
			cmd.add(lib);
		}

		for (d in conf.haxedef)
			switch (Type.typeof(d)) {
				case TClass(String):
					cmd.add("-D");
					cmd.add(cast d);
				case TObject:
					var key = Reflect.field(d, "key");
					var val = Reflect.field(d, "value");
					cmd.add("-D");
					cmd.add(val == null ? key : key + "=" + Std.string(val));
				default:
			}

		for (d in extraDefs) {
			cmd.add("-D");
			cmd.add(d);
		}

		cmd.add("-D");
		cmd.add(SystemUtil.platform);

		if (debug) {
			cmd.add("-D");
			cmd.add("debug");
			cmd.add("-D");
			cmd.add("HXCPP_DEBUGGER");
		};

		switch (tgt) {
			case Target.Cpp:
				cmd.add("-cpp");
				cmd.add(objDir);
			case Target.HL:
				final out = Path.join([outRoot, "bin", conf.app.file + ".hl"]);
				ensureDir(Path.directory(out));
				cmd.add("-hl");
				cmd.add(out);
			case Target.Neko:
				final out = Path.join([outRoot, "bin", conf.app.file + ".n"]);
				ensureDir(Path.directory(out));
				cmd.add("-neko");
				cmd.add(out);
			case Target.Java:
				final outDir = Path.join([outRoot, "bin"]);
				ensureDir(outDir);
				cmd.add("-java");
				cmd.add(outDir);
			case Target.JVM:
				final out = Path.join([outRoot, "bin", conf.app.file + ".jar"]);
				ensureDir(Path.directory(out));
				cmd.add("-jvm");
				cmd.add(out);
		}

		cmd.add("--macro");
		cmd.add("haxe.macro.Context.getModule('" + conf.app.main + "')");

		var code:Int = cmd.run();
		if (code != 0) {
			throw "haxe failed with exit " + code;
		}

		if (tgt.isCpp()) {
			finalizeCppBinary(outRoot, conf.app.file);
		}
	}

	private static inline function ensureDir(p:String):Void {
		if (!FileSystem.exists(p)) {
			FileSystem.createDirectory(p);
		}
	}

	public static function getTargetDir(t:Target):String {
		return switch (t) {
			case Target.Cpp:
				#if windows "windows" #else "linux" #end;
			case Target.HL: "hl";
			case Target.Neko: "neko";
			case Target.Java: "java";
			case Target.JVM: "jvm";
		}
	}

	private static function finalizeCppBinary(outRoot:String, appFile:String):Void {
		var obj:String = Path.join([outRoot, "obj", #if windows "ProgramMain.exe" #else "ProgramMain" #end]);
		var dstDir:String = Path.join([outRoot, "bin"]);
		ensureDir(dstDir);
		var dst:String = Path.join([dstDir, #if windows appFile + ".exe" #else appFile #end]);
		if (!FileSystem.exists(obj)) {
			throw 'Expected obj binary missing: $obj';
		}
		try {
			File.copy(obj, dst);
		} catch (e) {
			throw 'Copy failed: $e';
		}
		#if !windows
		// ensure exec bit
		Sys.command("chmod", ["+x", dst]);
		#end
		try {
			FileSystem.deleteFile(obj);
		} catch (_:Dynamic) {}
	}
}
