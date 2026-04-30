package aedifex.config;

import aedifex.build.Define;
import aedifex.build.ProjectSpec;
import aedifex.build.ProjectSpec.LibrarySpec;
import aedifex.build.internal.ProjectExtractor;
import aedifex.build.internal.ProjectProviderDiscovery;
import haxe.Json;
import haxe.io.Path;
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

	public static function loadProject(projectRoot:String):ProjectSpec {
		var buildFile = Path.join([projectRoot, "Aedifex.hx"]);
		if (FileSystem.exists(buildFile)) {
			var provider = ProjectProviderDiscovery.discover(projectRoot);
			return ProjectExtractor.extract(projectRoot, provider);
		}

		throw 'No project configuration found at $projectRoot. Expected Aedifex.hx';
	}

	public static function fromLegacy(cfg:AedifexConfig):ProjectSpec {
		var project = new ProjectSpec();
		var conf = cfg.config;

		project.meta.title = conf.meta.title;
		project.meta.version = conf.meta.version;
		project.meta.company = conf.meta.company;
		project.meta.authors = conf.meta.author != null ? conf.meta.author.copy() : [];

		project.app.mainClass = conf.app.main;
		project.app.path = conf.app.path;
		project.app.file = conf.app.file;

		if (conf.source != null && conf.source.path != null) {
			project.sources.push(conf.source.path);
		}

		for (lib in (conf.haxelib != null ? conf.haxelib : [])) {
			project.libraries.push(LibrarySpec.haxelib(lib));
		}

		for (item in (conf.haxedef != null ? conf.haxedef : [])) {
			switch (Type.typeof(item)) {
				case TClass(String):
					project.defines.push(Define.named(cast item));
				case TObject:
					var key = Reflect.field(item, "key");
					var value = Reflect.field(item, "value");
					project.defines.push(Define.named(key, value != null ? Std.string(value) : null));
				default:
			}
		}

		return project;
	}

	public static function toLegacy(project:ProjectSpec):AedifexConfig {
		var haxedef:Array<Dynamic> = [];
		for (define in (project.defines != null ? project.defines : [])) {
			if (define == null) continue;
			if (define.value == null) {
				haxedef.push(define.name);
			} else {
				haxedef.push({key: define.name, value: define.value});
			}
		}

		var haxelib:Array<String> = [];
		for (library in (project.libraries != null ? project.libraries : [])) {
			if (library != null && library.name != null && library.name.length > 0) {
				haxelib.push(library.name);
			}
		}

		return {
			config: {
				meta: {
					title: project.meta != null ? project.meta.title : null,
					version: project.meta != null ? project.meta.version : null,
					company: project.meta != null ? project.meta.company : null,
					author: project.meta != null && project.meta.authors != null ? project.meta.authors.copy() : []
				},
				app: {
					path: project.app != null ? project.app.path : "bin",
					main: project.app != null ? project.app.mainClass : "Main",
					file: project.app != null ? project.app.file : "Application"
				},
				source: {
					path: project.sources != null && project.sources.length > 0 ? project.sources[0] : "src"
				},
				haxelib: haxelib,
				haxedef: haxedef
			}
		};
	}
}
