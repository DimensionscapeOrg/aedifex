package aedifex.build.internal;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;

class ToolEnvironment {
	private static var cachedAedifexRoot:String = null;

	public static function getAedifexRoot():String {
		if (cachedAedifexRoot != null) return cachedAedifexRoot;

		var envRoot = resolveEnvironmentRoot();
		if (envRoot != null) {
			cachedAedifexRoot = envRoot;
			return cachedAedifexRoot;
		}

		var exeRoot = resolveExecutableRoot();
		if (exeRoot != null) {
			cachedAedifexRoot = exeRoot;
			return cachedAedifexRoot;
		}

		var localInvocationRoot = resolveLocalInvocationRoot();
		if (localInvocationRoot != null) {
			cachedAedifexRoot = localInvocationRoot;
			return cachedAedifexRoot;
		}

		var installedRoot = resolveInstalledRoot();
		if (installedRoot != null) {
			cachedAedifexRoot = installedRoot;
			return cachedAedifexRoot;
		}

		throw "Unable to locate the Aedifex library root for project extraction.";
	}

	public static function getInstalledLibraryRoot():Null<String> {
		var envRoot = resolveEnvironmentRoot();
		if (envRoot != null) {
			return envRoot;
		}

		return resolveInstalledRoot();
	}

	private static function resolveEnvironmentRoot():Null<String> {
		var value = Sys.getEnv("AEDIFEX_ROOT");
		if (value == null || value.length == 0) {
			return null;
		}

		var candidate = Path.normalize(value);
		return isToolRoot(candidate) ? candidate : null;
	}

	private static function resolveExecutableRoot():Null<String> {
		var programPath = try FileSystem.fullPath(Sys.programPath()) catch (_:Dynamic) Sys.programPath();
		if (programPath == null || programPath.length == 0) {
			return null;
		}

		var executableDirectory = Path.directory(programPath);
		if (executableDirectory == null || executableDirectory.length == 0) {
			return null;
		}

		var candidate = Path.normalize(Path.join([executableDirectory, ".."]));
		if (isToolRoot(candidate)) {
			return candidate;
		}

		return null;
	}

	private static function resolveLocalInvocationRoot():Null<String> {
		if (Sys.getEnv("HAXELIB_RUN") == "1") {
			return null;
		}

		var cwdRoot = Path.normalize(Sys.getCwd());
		if (!isToolRoot(cwdRoot)) {
			return null;
		}

		var programName = Path.withoutDirectory(Sys.programPath()).toLowerCase();
		if (programName == "neko" || programName == "neko.exe" || programName == "haxe" || programName == "haxe.exe" || StringTools.endsWith(programName, ".n")) {
			return cwdRoot;
		}

		return null;
	}

	private static function resolveInstalledRoot():Null<String> {
		try {
			var process = new Process("haxelib", ["libpath", "aedifex"]);
			var stdout = process.stdout.readAll().toString();
			process.close();
			for (line in stdout.split("\n")) {
				var trimmed = StringTools.trim(line);
				if (trimmed.length == 0 || StringTools.startsWith(trimmed, "-")) continue;
				var candidate = Path.normalize(trimmed);
				if (isToolRoot(candidate)) {
					return candidate;
				}
			}
		} catch (_:Dynamic) {}

		return null;
	}

	private static function isToolRoot(path:String):Bool {
		return FileSystem.exists(Path.join([path, "src", "aedifex"]))
			&& FileSystem.exists(Path.join([path, "src", "aedifex", "cli", "Main.hx"]));
	}
}
