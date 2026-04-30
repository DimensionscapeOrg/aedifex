package aedifex.cli;

import aedifex.build._internal.ToolEnvironment;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

@:dox(hide)
class ExtensionTools {
	private static inline final EXTENSION_DIR = "tools/vscode-extension";

	public static function run(args:Array<String>):Void {
		var action = normalizeAction(args);
		switch (action) {
			case "package":
				var vsixPath = packageVsCodeExtension();
				Sys.println("Created VS Code extension package: " + vsixPath);
			default:
				throw "Unknown extension action: " + action;
		}
	}

	public static function packageVsCodeExtension():String {
		var root = resolveCheckoutRoot();
		var extensionDir = Path.join([root, EXTENSION_DIR]);
		if (!FileSystem.exists(extensionDir) || !FileSystem.isDirectory(extensionDir)) {
			throw "VS Code extension sources were not found. This command is only available from an Aedifex source checkout.";
		}

		var packageInfo = loadExtensionPackageInfo(extensionDir);
		Sys.println("Packaging VS Code extension...");
		var code = runIn(extensionDir, packageCommand(), packageArgs());
		if (code != 0) {
			throw "VS Code extension packaging failed with exit " + code;
		}

		var vsixPath = Path.join([extensionDir, packageInfo.name + "-" + packageInfo.version + ".vsix"]);
		if (!FileSystem.exists(vsixPath)) {
			throw "VS Code extension packaging completed, but no VSIX was found at " + vsixPath;
		}
		return vsixPath;
	}

	private static function normalizeAction(args:Array<String>):String {
		if (args == null || args.length == 0) return "package";
		return switch (StringTools.trim(args[0]).toLowerCase()) {
			case "package", "rebuild":
				"package";
			default:
				args[0];
		};
	}

	private static function resolveCheckoutRoot():String {
		var root = try ToolEnvironment.getAedifexRoot() catch (_:Dynamic) null;
		if (root == null || root.length == 0) {
			root = Path.normalize(Sys.getCwd());
		}
		return Path.normalize(root);
	}

	private static function packageCommand():String {
		return isWindowsHost() ? "cmd" : "npx";
	}

	private static function packageArgs():Array<String> {
		return isWindowsHost()
			? ["/c", "npx.cmd", "@vscode/vsce", "package", "--pre-release"]
			: ["@vscode/vsce", "package", "--pre-release"];
	}

	private static function loadExtensionPackageInfo(extensionDir:String):{name:String, version:String} {
		var packageJsonPath = Path.join([extensionDir, "package.json"]);
		if (!FileSystem.exists(packageJsonPath)) {
			throw "VS Code extension package.json was not found at " + packageJsonPath;
		}

		var payload:Dynamic = Json.parse(File.getContent(packageJsonPath));
		var name:String = Reflect.field(payload, "name");
		var version:String = Reflect.field(payload, "version");
		if (name == null || name.length == 0) {
			throw "VS Code extension package.json is missing a package name.";
		}
		if (version == null || version.length == 0) {
			throw "VS Code extension package.json is missing a version.";
		}
		return {name: name, version: version};
	}

	private static function runIn(cwd:String, command:String, args:Array<String>):Int {
		var previous = Sys.getCwd();
		var failure:Dynamic = null;
		var exitCode = -1;
		try {
			Sys.setCwd(cwd);
			exitCode = Sys.command(command, args);
		} catch (error:Dynamic) {
			failure = error;
		}
		Sys.setCwd(previous);
		if (failure != null) throw failure;
		return exitCode;
	}

	private static function isWindowsHost():Bool {
		return Sys.systemName().toLowerCase() == "windows";
	}
}
