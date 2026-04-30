package aedifex.build._internal;

import aedifex.build.ProjectSpec;
import aedifex.build._internal.ProjectProviderDiscovery.DiscoveredProjectProvider;
import aedifex.build._internal.ProjectProviderDiscovery.ProjectProviderKind;
import haxe.Unserializer;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

class ProjectExtractor {
	public static function extract(cwd:String, provider:DiscoveredProjectProvider):ProjectSpec {
		var stateRoot = Path.join([cwd, ".aedifex"]);
		var tempDirectory = Path.join([stateRoot, "tmp"]);
		ensureDir(stateRoot);
		ensureDir(tempDirectory);

		var runnerPath = Path.join([tempDirectory, "AedifexProjectExtractRunner.hx"]);
		File.saveContent(runnerPath, buildRunnerSourceForProvider(provider));

		var args = ["--cwd", cwd];
		for (classPath in collectProjectClassPaths(cwd, provider, tempDirectory)) {
			args.push("-cp");
			args.push(classPath);
		}
		args.push("-cp");
		args.push(Path.join([ToolEnvironment.getAedifexRoot(), "src"]));
		args.push("-main");
		args.push("AedifexProjectExtractRunner");
		args.push("--interp");

		var result = capture("haxe", args);
		if (result.code != 0) {
			throw "Failed to extract Aedifex project config from `" + provider.className + "`.\n" + StringTools.trim(result.stderr + "\n" + result.stdout);
		}

		for (line in result.stdout.split("\n")) {
			if (!StringTools.startsWith(line, "__AEDIFEX_PROJECT__")) continue;
			var payload = line.substr("__AEDIFEX_PROJECT__".length);
			return cast Unserializer.run(payload);
		}

		throw "The Aedifex project extractor did not produce any project data for `" + provider.className + "`.";
	}

	private static function buildRunnerSourceForProvider(provider:DiscoveredProjectProvider):String {
		var lines:Array<String> = [
			"package;",
			"",
			"class AedifexProjectExtractRunner",
			"{",
			"\tpublic static function main():Void",
			"\t{",
			"\t\tvar project:aedifex.build.ProjectSpec = " + provider.className + ".project;",
			'\t\tSys.println("__AEDIFEX_PROJECT__" + haxe.Serializer.run(project));',
			"\t}",
			"}",
			""
		];
		return lines.join("\n");
	}

	private static function collectProjectClassPaths(cwd:String, provider:DiscoveredProjectProvider, tempDirectory:String):Array<String> {
		var results:Array<String> = [];
		var seen:Map<String, Bool> = new Map();

		addClassPath(results, seen, provider.sourceRoot);
		if (provider.kind == ProjectProviderKind.BUILD_FILE) {
			appendLikelySourceRoots(Path.normalize(cwd), results, seen);
		}
		addClassPath(results, seen, tempDirectory);
		return results;
	}

	private static function appendLikelySourceRoots(directory:String, results:Array<String>, seen:Map<String, Bool>):Void {
		appendSourceRootIfPresent(Path.join([directory, "src"]), results, seen);
		appendSourceRootIfPresent(Path.join([directory, "source"]), results, seen);

		for (entry in FileSystem.readDirectory(directory)) {
			var fullPath = Path.join([directory, entry]);
			if (!FileSystem.isDirectory(fullPath)) continue;
			if (shouldSkipDirectory(entry)) continue;
			appendSourceRootIfPresent(Path.join([fullPath, "src"]), results, seen);
			appendSourceRootIfPresent(Path.join([fullPath, "source"]), results, seen);
		}
	}

	private static function appendSourceRootIfPresent(directory:String, results:Array<String>, seen:Map<String, Bool>):Void {
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return;
		if (!containsHaxeSource(directory)) return;
		addClassPath(results, seen, directory);
	}

	private static function addClassPath(results:Array<String>, seen:Map<String, Bool>, path:String):Void {
		var normalized = Path.normalize(path);
		if (seen.exists(normalized)) return;
		seen.set(normalized, true);
		results.push(normalized);
	}

	private static function shouldSkipDirectory(name:String):Bool {
		return name == ".git" || name == ".aedifex" || name == "bin" || name == "obj" || name == "node_modules";
	}

	private static function containsHaxeSource(directory:String):Bool {
		for (entry in FileSystem.readDirectory(directory)) {
			var fullPath = Path.join([directory, entry]);
			if (FileSystem.isDirectory(fullPath)) {
				if (shouldSkipDirectory(entry)) continue;
				if (containsHaxeSource(fullPath)) return true;
				continue;
			}

			if (StringTools.endsWith(entry, ".hx")) return true;
		}

		return false;
	}

	private static function ensureDir(path:String):Void {
		if (path == null || path.length == 0 || FileSystem.exists(path)) return;
		var parent = Path.directory(path);
		if (parent != null && parent != "" && parent != path && !FileSystem.exists(parent)) {
			ensureDir(parent);
		}
		FileSystem.createDirectory(path);
	}

	private static function capture(exe:String, args:Array<String>):{code:Int, stdout:String, stderr:String} {
		var process = new Process(exe, args);
		var stdout = "";
		var stderr = "";
		try {
			stdout = process.stdout.readAll().toString();
		} catch (_:Dynamic) {}
		try {
			stderr = process.stderr.readAll().toString();
		} catch (_:Dynamic) {}
		var code = process.exitCode();
		process.close();
		return {code: code, stdout: stdout, stderr: stderr};
	}
}
