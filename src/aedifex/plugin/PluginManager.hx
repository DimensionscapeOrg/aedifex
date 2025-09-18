package aedifex.plugin;

import haxe.ds.StringMap;
import haxe.io.Path;
import sys.FileSystem;

class PluginManager {
	private static var _pluginPath:String;
	private static inline var DEFAULT_DIR = "plugins";

	private var _pluginsFiles:Array<String>;
	private var _plugins:StringMap<Plugin> = new StringMap();

	public function new(?customPath:String) {
		_pluginPath = resolvePluginPath(customPath);
		ensureDir(_pluginPath);
		_pluginsFiles = discover();
		for (path in _pluginsFiles) {
			load(path);
		}
	}

	public function get(name:String):Null<Plugin> {
		return _plugins.get(name);
	}

	public function listNames():Array<String> {
		return [for (k in _plugins.keys()) k];
	}

	private function load(path:String):Void {
		var plugin:Plugin = new Plugin(path);
		try {
			if (!plugin.init(Aedifex.version)) {
				plugin.close();
				return;
			}
		} catch (_:Dynamic) {
			plugin.close();
			return;
		}
		_plugins.set(plugin.name, plugin);
	}

	private static function resolvePluginPath(?custom:String):String {
		if (custom != null && custom != "") {
			return Path.normalize(custom);
		}

		var env:String = Sys.getEnv("AEDIFEX_PLUGINS");
		if (env != null && env != "") {
			return Path.normalize(env);
		}

		var base:String = Path.directory(Sys.programPath());
		return Path.join([base, DEFAULT_DIR]);
	}

	private static inline function ensureDir(path:String):Void {
		if (!FileSystem.exists(path)) {
			FileSystem.createDirectory(path);
		}
	}

	public function discover():Array<String> {
		var paths:Array<String> = new Array<String>();
		for (item in FileSystem.readDirectory(_pluginPath)) {
			var full:String = Path.join([_pluginPath, item]);
			if (FileSystem.isDirectory(full)) {
				var candidate:String = Path.join([full, "plugin"]);
				if (FileSystem.exists(candidate) && !FileSystem.isDirectory(candidate)) {
					paths.push(candidate);
				}
			} else {
				paths.push(full);
			}
		}
		return paths;
	}
}
