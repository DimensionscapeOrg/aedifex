package ci;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class DocsTool {
	private static inline final DIST_ROOT = "dist/docs";
	private static inline final TMP_ROOT = "dist/docs/_tmp";
	private static inline final API_ROOT = "dist/docs/api";
	private static inline final GUIDE_ROOT = "dist/docs/guide";
	private static inline final REFERENCE_ROOT = "dist/docs/reference";
	private static inline final GENERATED_DOCS_PREFIX = "dist/docs/";

	public static function main():Void {
		buildDocs();
	}

	public static function buildDocs():Void {
		validateDocs();
		resetDirectory(DIST_ROOT);
		buildApiDocs();
		copyTree("docs/guide", GUIDE_ROOT);
		copyReferenceDocs();
		writeLandingReadme();
	}

	public static function buildApiDocs():Void {
		ensureDoxInstalled();
		ensureDirectory(TMP_ROOT);
		ensureDirectory(API_ROOT);

		var xmlPath = Path.join([TMP_ROOT, "aedifex.xml"]);
		var stubOutput = Path.join([TMP_ROOT, "aedifex-docs.n"]);
		run("haxe", [
			"-cp", "src",
			"-neko", stubOutput,
			"-xml", xmlPath,
			"--macro", "include('aedifex.build')",
			"--macro", "include('aedifex.plugin')",
			"--macro", "include('aedifex.core.BuildContext')"
		]);

		run("haxelib", [
			"run", "dox",
			"-i", xmlPath,
			"-o", API_ROOT,
			"--title", "Aedifex API",
			"--toplevel-package", "aedifex",
			"-in", "^aedifex\\.build($|\\.)",
			"-in", "^aedifex\\.plugin($|\\.)",
			"-in", "^aedifex\\.core\\.BuildContext$",
			"-ex", "^aedifex\\.build\\._internal($|\\.)",
			"-ex", "^aedifex\\.build\\.macros($|\\.)",
			"-ex", "^aedifex\\.setup($|\\.)",
			"-ex", "^aedifex\\.cli($|\\.)",
			"-D", "description", "Curated Aedifex public API for the typed build model, extension surface, and plugin surface."
		]);
	}

	public static function validateDocs():Void {
		var files = collectMarkdownFiles();
		var errors:Array<String> = [];
		for (file in files) {
			validateMarkdownFile(file, errors);
		}

		if (errors.length > 0) {
			for (error in errors) {
				Sys.println(error);
			}
			fail("Docs validation failed with " + errors.length + " broken link(s).");
		}

		Sys.println("Docs validation passed for " + files.length + " markdown files.");
	}

	private static function validateMarkdownFile(path:String, errors:Array<String>):Void {
		var lines = File.getContent(path).split("\n");
		var inFence = false;
		var markdownLink = ~/!?\[([^\]]+)\]\(([^)]+)\)/;
		for (lineIndex in 0...lines.length) {
			var line = lines[lineIndex];
			var trimmed = StringTools.trim(line);
			if (StringTools.startsWith(trimmed, "```")) {
				inFence = !inFence;
				continue;
			}
			if (inFence) {
				continue;
			}

			var offset = 0;
			while (offset < line.length && markdownLink.matchSub(line, offset)) {
				var rawTarget = StringTools.trim(markdownLink.matched(2));
				offset = markdownLink.matchedPos().pos + markdownLink.matchedPos().len;
				if (!shouldValidateTarget(rawTarget)) {
					continue;
				}

				var cleanTarget = rawTarget;
				var anchorIndex = cleanTarget.indexOf("#");
				if (anchorIndex >= 0) {
					cleanTarget = cleanTarget.substr(0, anchorIndex);
				}
				cleanTarget = normalizeMarkdownPath(cleanTarget);
				if (cleanTarget.length == 0 || StringTools.startsWith(cleanTarget, GENERATED_DOCS_PREFIX)) {
					continue;
				}

				var resolved = Path.normalize(Path.join([Path.directory(path), cleanTarget]));
				if (!FileSystem.exists(resolved)) {
					errors.push(path + ":" + (lineIndex + 1) + " -> missing " + cleanTarget);
				}
			}
		}
	}

	private static function shouldValidateTarget(target:String):Bool {
		if (target == null || target.length == 0) {
			return false;
		}
		var lower = target.toLowerCase();
		if (StringTools.startsWith(lower, "http://")
			|| StringTools.startsWith(lower, "https://")
			|| StringTools.startsWith(lower, "mailto:")
			|| StringTools.startsWith(lower, "app://")
			|| StringTools.startsWith(lower, "plugin://")
			|| StringTools.startsWith(lower, "file://")
			|| StringTools.startsWith(lower, "#")) {
			return false;
		}
		if (~/^[a-zA-Z]:[\/\\]/.match(target)) {
			return false;
		}
		return true;
	}

	private static function normalizeMarkdownPath(value:String):String {
		var path = value;
		if ((StringTools.startsWith(path, "'") && StringTools.endsWith(path, "'"))
			|| (StringTools.startsWith(path, "\"") && StringTools.endsWith(path, "\""))) {
			path = path.substr(1, path.length - 2);
		}
		return path;
	}

	private static function collectMarkdownFiles():Array<String> {
		var files = ["README.md"];
		for (path in listMarkdownFiles("docs")) {
			files.push(path);
		}
		files.sort(Reflect.compare);
		return files;
	}

	private static function listMarkdownFiles(root:String):Array<String> {
		var files:Array<String> = [];
		if (!FileSystem.exists(root)) {
			return files;
		}
		for (entry in FileSystem.readDirectory(root)) {
			var path = Path.join([root, entry]);
			if (FileSystem.isDirectory(path)) {
				for (child in listMarkdownFiles(path)) {
					files.push(child);
				}
			} else if (StringTools.endsWith(entry.toLowerCase(), ".md")) {
				files.push(Path.normalize(path));
			}
		}
		return files;
	}

	private static function copyReferenceDocs():Void {
		ensureDirectory(REFERENCE_ROOT);
		for (entry in FileSystem.readDirectory("docs")) {
			var source = Path.join(["docs", entry]);
			if (FileSystem.isDirectory(source)) {
				if (entry == "guide") {
					continue;
				}
				copyTree(source, Path.join([REFERENCE_ROOT, entry]));
			} else if (StringTools.endsWith(entry.toLowerCase(), ".md")) {
				copyFile(source, Path.join([REFERENCE_ROOT, entry]));
			}
		}
	}

	private static function copyTree(source:String, destination:String):Void {
		ensureDirectory(destination);
		for (entry in FileSystem.readDirectory(source)) {
			var sourcePath = Path.join([source, entry]);
			var destinationPath = Path.join([destination, entry]);
			if (FileSystem.isDirectory(sourcePath)) {
				copyTree(sourcePath, destinationPath);
			} else {
				copyFile(sourcePath, destinationPath);
			}
		}
	}

	private static function copyFile(source:String, destination:String):Void {
		ensureDirectory(Path.directory(destination));
		File.saveBytes(destination, File.getBytes(source));
	}

	private static function writeLandingReadme():Void {
		var content = [
			"# Aedifex Docs",
			"",
			"This build artifact splits Aedifex docs into curated guides, reference prose, and generated API docs.",
			"",
			"## Start Here",
			"",
			"- [Guide index](guide/README.md)",
			"- [Getting started](guide/getting-started.md)",
			"- [Building apps](guide/building-apps.md)",
			"- [Using the VS Code extension](guide/vscode/using-the-extension.md)",
			"- [Building plugins](guide/building-plugins.md)",
			"- [Building your own CLI tool](guide/building-your-own-cli-tool.md)",
			"",
			"## Reference",
			"",
			"- [Project model](reference/project-model.md)",
			"- [Extensions](reference/extensions.md)",
			"- [Defines](reference/defines.md)",
			"- [Architecture](reference/architecture.md)",
			"- [Installation and deployment](reference/installation-and-deployment.md)",
			"- [VS Code extension reference](reference/vscode-extension.md)",
			"",
			"## API",
			"",
			"- [Curated API docs](api/index.html)",
			""
		].join("\n");
		File.saveContent(Path.join([DIST_ROOT, "README.md"]), content);
	}

	private static function ensureDoxInstalled():Void {
		var code = Sys.command("haxelib", ["path", "dox"]);
		if (code != 0) {
			fail("Dox is not installed. Run 'haxelib install dox' first.");
		}
	}

	private static function run(command:String, args:Array<String>):Void {
		Sys.println("> " + command + " " + args.join(" "));
		var code = Sys.command(command, args);
		if (code != 0) {
			fail(command + " exited with code " + code);
		}
	}

	private static function resetDirectory(path:String):Void {
		if (FileSystem.exists(path)) {
			deleteTree(path);
		}
		ensureDirectory(path);
	}

	private static function deleteTree(path:String):Void {
		if (!FileSystem.exists(path)) {
			return;
		}
		if (FileSystem.isDirectory(path)) {
			for (entry in FileSystem.readDirectory(path)) {
				deleteTree(Path.join([path, entry]));
			}
			FileSystem.deleteDirectory(path);
			return;
		}
		FileSystem.deleteFile(path);
	}

	private static function ensureDirectory(path:String):Void {
		if (path == null || path.length == 0 || path == ".") {
			return;
		}
		if (FileSystem.exists(path)) {
			return;
		}
		var parent = Path.directory(path);
		if (parent != null && parent.length > 0 && parent != path) {
			ensureDirectory(parent);
		}
		FileSystem.createDirectory(path);
	}

	private static function fail(message:String):Void {
		Sys.println(message);
		Sys.exit(1);
	}
}
