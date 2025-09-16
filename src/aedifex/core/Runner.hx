package aedifex.core;

import aedifex.config.AedifexConfig;
import haxe.io.Path;

class Runner {
	public static function run(cfg:AedifexConfig, tgt:Target, projectRoot:String):Void {
		var conf = cfg.config;
		var root:String = Path.join([projectRoot, conf.app.path, Builder.getTargetDir(tgt), "bin"]);

		var cmd:Command = new Command();
		switch (tgt) {
			case Target.Cpp:
				var exe:String = #if windows conf.app.file + ".exe" #else conf.app.file #end;
				cmd.add(Path.join([root, exe]));
			case Target.HL:
				cmd.add("hl");
				cmd.add(Path.join([root, conf.app.file + ".hl"]));
			case Target.Neko:
				cmd.add("neko");
				cmd.add(Path.join([root, conf.app.file + ".n"]));
			case Target.Java:
				cmd.add("java");
				cmd.add("-cp");
				cmd.add(root);
				cmd.add(conf.app.main);
			case Target.JVM:
				cmd.add("java");
				cmd.add("-jar");
				cmd.add(Path.join([root, conf.app.file + ".jar"]));
		}
		var code:Int = cmd.run();
		if (code != 0) {
			throw "run failed with exit " + code;
		}
	}
}
