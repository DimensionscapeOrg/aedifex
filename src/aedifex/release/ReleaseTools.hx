package aedifex.release;

import aedifex.build.ProjectSpec;
import aedifex.build._internal.ProjectResolver;
import aedifex.config.Loader;
import aedifex.cli.Main;
import haxe.crypto.Crc32;
import haxe.io.Path;
import haxe.ds.List;
import haxe.zip.Entry;
import haxe.zip.Writer;
import sys.FileSystem;
import sys.io.File;

class ReleaseTools {
	public static function packageHaxelib(projectRoot:String, validate:Bool):String {
		var normalizedRoot = Path.normalize(projectRoot);
		var project = Loader.loadProject(normalizedRoot);
		var resolved = ProjectResolver.resolve(project);
		var json = Main.buildHaxelibJson(resolved);
		File.saveContent(Path.join([normalizedRoot, "haxelib.json"]), json);

		var version = resolved.haxelib != null ? resolved.haxelib.version : null;
		if (version == null || version.length == 0) {
			throw "Cannot package haxelib release without a version.";
		}

		var packageName = resolved.haxelib.name != null && resolved.haxelib.name.length > 0 ? resolved.haxelib.name : resolved.meta.name;
		if (packageName == null || packageName.length == 0) {
			throw "Cannot package haxelib release without a package name.";
		}

		var distRoot = Path.join([normalizedRoot, "dist"]);
		var stageRoot = Path.join([distRoot, "haxelib"]);
		var stageDir = Path.join([stageRoot, packageName + "-" + version]);
		var zipPath = Path.join([distRoot, packageName + "-" + version + ".zip"]);

		deleteRecursive(stageDir);
		if (FileSystem.exists(zipPath)) {
			FileSystem.deleteFile(zipPath);
		}

		ensureDir(stageDir);

		for (relativePath in releaseFilesFor(normalizedRoot, resolved)) {
			copyPath(normalizedRoot, stageDir, relativePath);
		}

		createZipFromDirectory(stageDir, zipPath);

		if (validate) {
			validateHaxelibPackage(zipPath);
		}

		return zipPath;
	}

	public static function validateHaxelibPackage(zipPath:String):Void {
		var normalizedZip = Path.normalize(zipPath);
		if (!FileSystem.exists(normalizedZip)) {
			throw "Package zip not found: " + normalizedZip;
		}

		var tempRoot = Path.join([Sys.getEnv("TEMP") != null ? Sys.getEnv("TEMP") : Sys.getCwd(), "aedifex-haxelib-validate-" + Std.string(Date.now().getTime())]);
		var sampleRoot = Path.join([tempRoot, "sample"]);
		ensureDir(tempRoot);

		var failure:Dynamic = null;
		try {
			runIn(tempRoot, "haxelib", ["newrepo"]);
			runIn(tempRoot, "haxelib", ["install", normalizedZip]);
			runIn(tempRoot, "haxelib", ["run", "aedifex", "profiles", "-json"]);
			runIn(tempRoot, "haxelib", ["run", "aedifex", "create", sampleRoot]);
			runIn(tempRoot, "haxelib", ["run", "aedifex", "build", "neko", sampleRoot, "-debug"]);
		} catch (error:Dynamic) {
			failure = error;
		}
		deleteRecursive(tempRoot);
		if (failure != null) throw failure;
	}

	private static function releaseFilesFor(root:String, project:ProjectSpec):Array<String> {
		var results:Array<String> = [];
		appendIfPresent(root, results, "Aedifex.hx");
		appendIfPresent(root, results, "CHANGELOG.md");
		appendIfPresent(root, results, "LICENSE");
		appendIfPresent(root, results, "README.md");
		appendIfPresent(root, results, "build.hxml");
		appendIfPresent(root, results, "ci");
		appendIfPresent(root, results, "docs");
		appendIfPresent(root, results, "haxelib.json");
		appendIfPresent(root, results, "run.hxml");
		appendIfPresent(root, results, "run.n");

		for (source in (project.sources != null ? project.sources : [])) {
			appendIfPresent(root, results, source);
		}

		appendIfPresent(root, results, "template");
		return results;
	}

	private static function appendIfPresent(root:String, results:Array<String>, relativePath:String):Void {
		if (relativePath == null || relativePath.length == 0) return;
		if (results.indexOf(relativePath) != -1) return;
		if (FileSystem.exists(Path.join([root, relativePath]))) {
			results.push(relativePath);
		}
	}

	private static function copyPath(root:String, stageRoot:String, relativePath:String):Void {
		var source = Path.join([root, relativePath]);
		var destination = Path.join([stageRoot, relativePath]);
		if (FileSystem.isDirectory(source)) {
			copyDirectory(source, destination);
		} else {
			ensureDir(Path.directory(destination));
			File.copy(source, destination);
		}
	}

	private static function copyDirectory(source:String, destination:String):Void {
		ensureDir(destination);
		for (name in FileSystem.readDirectory(source)) {
			var sourcePath = Path.join([source, name]);
			var destinationPath = Path.join([destination, name]);
			if (FileSystem.isDirectory(sourcePath)) {
				copyDirectory(sourcePath, destinationPath);
			} else {
				ensureDir(Path.directory(destinationPath));
				File.copy(sourcePath, destinationPath);
			}
		}
	}

	private static function createZipFromDirectory(directory:String, zipPath:String):Void {
		var entries:List<Entry> = new List();
		collectEntries(directory, directory, entries);
		var output = File.write(zipPath, true);
		var failure:Dynamic = null;
		try {
			var writer = new Writer(output);
			writer.write(entries);
		} catch (error:Dynamic) {
			failure = error;
		}
		output.close();
		if (failure != null) throw failure;
	}

	private static function collectEntries(root:String, current:String, entries:List<Entry>):Void {
		for (name in FileSystem.readDirectory(current)) {
			var path = Path.join([current, name]);
			if (FileSystem.isDirectory(path)) {
				collectEntries(root, path, entries);
				continue;
			}
			var relativePath = Path.normalize(path.substr(root.length + 1));
			var bytes = File.getBytes(path);
			entries.push({
				fileName: StringTools.replace(relativePath, "\\", "/"),
				fileSize: bytes.length,
				fileTime: Date.now(),
				compressed: false,
				dataSize: bytes.length,
				data: bytes,
				crc32: Crc32.make(bytes),
				extraFields: null
			});
		}
	}

	private static function runIn(cwd:String, command:String, args:Array<String>):Void {
		var previous = Sys.getCwd();
		var code = -1;
		var failure:Dynamic = null;
		try {
			Sys.setCwd(cwd);
			code = Sys.command(command, args);
		} catch (error:Dynamic) {
			failure = error;
		}
		Sys.setCwd(previous);
		if (failure != null) throw failure;
		if (code != 0) {
			throw command + " failed with exit " + code;
		}
	}

	private static function ensureDir(path:String):Void {
		if (path == null || path.length == 0 || FileSystem.exists(path)) return;
		var parent = Path.directory(path);
		if (parent != null && parent != "" && parent != path) {
			ensureDir(parent);
		}
		FileSystem.createDirectory(path);
	}

	private static function deleteRecursive(path:String):Void {
		if (!FileSystem.exists(path)) return;
		if (!FileSystem.isDirectory(path)) {
			FileSystem.deleteFile(path);
			return;
		}
		for (name in FileSystem.readDirectory(path)) {
			deleteRecursive(Path.join([path, name]));
		}
		FileSystem.deleteDirectory(path);
	}
}
