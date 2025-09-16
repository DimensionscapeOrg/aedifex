package aedifex.config;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;

class Loader {
	public static function load(path:String):AedifexConfig {
		if (!FileSystem.exists(path)) {
			throw 'No project configuration at $path';
		}

		var txt:String = File.getContent(path);
		try {
			return cast Json.parse(txt);
		} catch (e) {
			throw 'Config parse error: $e';
		}
	}
}
