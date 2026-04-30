package aedifex.build._internal;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class ProjectProviderDiscovery {
	private static inline final ROOT_PROJECT_CONFIG_FILE:String = "Aedifex.hx";
	private static inline final ROOT_PROJECT_CONFIG_CLASS:String = "Aedifex";

	public static function discover(cwd:String):DiscoveredProjectProvider {
		var root = Path.normalize(cwd);
		var buildFile = Path.join([root, ROOT_PROJECT_CONFIG_FILE]);
		if (FileSystem.exists(buildFile)) {
			return parseBuildFileProvider(buildFile);
		}

		var matches:Array<DiscoveredProjectProvider> = [];
		scan(root, matches);

		if (matches.length == 0) {
			throw "No Aedifex project config was found. Create `Aedifex.hx` with `public static final project`.";
		}

		if (matches.length > 1) {
			var details = [];
			for (match in matches) {
				details.push(match.className + " [" + match.filePath + "]");
			}
			throw "Multiple inline Aedifex project configs were found:\n- " + details.join("\n- ") + "\nUse `Aedifex.hx` to make the project root explicit.";
		}

		return matches[0];
	}

	private static function parseBuildFileProvider(filePath:String):DiscoveredProjectProvider {
		var content = File.getContent(filePath);
		var packageName = parsePackageName(content);
		if (packageName != null && packageName.length > 0) {
			throw "`Aedifex.hx` must stay in the root package. Use `package;` or omit the package declaration.";
		}

		if (!~/(?m)^\s*(?:public\s+)?static\s+(?:final|var)\s+project\b/.match(content)) {
			throw "`Aedifex.hx` must expose `public static final project` from a root `class Aedifex`.";
		}

		if (!(new EReg("class\\s+" + ROOT_PROJECT_CONFIG_CLASS + "\\b", "")).match(content)) {
			throw "`Aedifex.hx` must define a root `class Aedifex` so the tool has one stable export convention.";
		}

		return new DiscoveredProjectProvider(ProjectProviderKind.BUILD_FILE, ROOT_PROJECT_CONFIG_CLASS, Path.normalize(filePath), Path.normalize(Path.directory(filePath)));
	}

	private static function scan(directory:String, matches:Array<DiscoveredProjectProvider>):Void {
		for (entry in FileSystem.readDirectory(directory)) {
			var fullPath = Path.join([directory, entry]);
			if (FileSystem.isDirectory(fullPath)) {
				if (shouldSkipDirectory(entry)) continue;
				scan(fullPath, matches);
			} else if (StringTools.endsWith(entry, ".hx")) {
				if (entry == ROOT_PROJECT_CONFIG_FILE) continue;
				var content = File.getContent(fullPath);
				if (!~/(?m)^\s*(?:public\s+)?static\s+(?:final|var)\s+project\b/.match(content)) continue;
				matches.push(parseProvider(fullPath, ProjectProviderKind.INLINE_ENTRY));
			}
		}
	}

	private static function parseProvider(filePath:String, kind:ProjectProviderKind):DiscoveredProjectProvider {
		var content = File.getContent(filePath);
		var packageName = parsePackageName(content);

		var classMatch = ~/class\s+([A-Za-z_][A-Za-z0-9_]*)/;
		if (!classMatch.match(content)) {
			throw "Unable to determine the config provider class for `" + filePath + "`.";
		}

		var className = classMatch.matched(1);
		var moduleName = Path.withoutExtension(Path.withoutDirectory(filePath));
		var qualifiedModule = packageName != null && packageName.length > 0 ? packageName + "." + moduleName : moduleName;
		var qualified = moduleName == className ? (packageName != null && packageName.length > 0 ? packageName + "." + className : className) : qualifiedModule + "." + className;
		var sourceRoot = deriveSourceRoot(filePath, packageName);
		return new DiscoveredProjectProvider(kind, qualified, Path.normalize(filePath), sourceRoot);
	}

	private static function parsePackageName(content:String):String {
		var packageName = "";
		var packageMatch = ~/(?m)^\s*package\s*([A-Za-z0-9_.]*)\s*;/;
		if (packageMatch.match(content)) {
			packageName = packageMatch.matched(1);
		}
		return packageName;
	}

	private static function deriveSourceRoot(filePath:String, packageName:String):String {
		var directory = Path.normalize(Path.directory(filePath));
		if (packageName == null || packageName.length == 0) return directory;

		var sourceRoot = directory;
		for (_ in packageName.split(".")) {
			sourceRoot = Path.normalize(Path.directory(sourceRoot));
		}
		return sourceRoot;
	}

	private static function shouldSkipDirectory(name:String):Bool {
		return name == ".git" || name == ".aedifex" || name == "bin" || name == "obj" || name == "node_modules";
	}
}

class DiscoveredProjectProvider {
	public var kind:ProjectProviderKind;
	public var className:String;
	public var filePath:String;
	public var sourceRoot:String;

	public function new(kind:ProjectProviderKind, className:String, filePath:String, sourceRoot:String) {
		this.kind = kind;
		this.className = className;
		this.filePath = filePath;
		this.sourceRoot = sourceRoot;
	}
}

enum ProjectProviderKind {
	BUILD_FILE;
	INLINE_ENTRY;
}
