package aedifex.core;

import haxe.Resource;
import sys.FileSystem;
import sys.io.File;

class ProgramWriter {
	public static function ensure(hxDir:String, mainClass:String):Void {
		if (!FileSystem.exists(hxDir)) {
			FileSystem.createDirectory(hxDir);
		}

		var tmpl:String = Resource.getString("ProgramMain");
		if (tmpl == null) {
			throw "Missing resource: ProgramMain";
		}

		var content:String = new EReg("::.*::", "g").replace(tmpl, mainClass);
		File.saveContent(hxDir + "/ProgramMain.hx", content);
	}
}
