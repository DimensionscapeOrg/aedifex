package aedifex.cli;

import aedifex.build._internal.ToolEnvironment;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

@:dox(hide)
class CliSetup {
	public static inline final CLI_NAME:String = "aedifex";

	public static function run(args:Array<String>):Int {
		var action = normalizeAction(args);
		var haxeRoot = resolveHaxeRoot();

		return switch (action) {
			case "status":
				printStatus(haxeRoot);
				0;
			case "remove":
				remove(haxeRoot);
				0;
			default:
				install(haxeRoot);
				maybeRegisterCurrentCheckout();
				0;
		};
	}

	public static function install(targetDirectory:String):Void {
		ensureDirectoryWritable(targetDirectory);

		for (entry in buildEntries()) {
			var targetPath = Path.join([targetDirectory, entry.name]);
			writeIfChanged(targetPath, entry.content);
			if (entry.executable) ensureExecutable(targetPath);
			Sys.println("Installed " + targetPath);
		}

		Sys.println("");
		Sys.println("Aedifex CLI is now available from the Haxe tool directory:");
		Sys.println("  " + targetDirectory);
		Sys.println("");
		Sys.println("You can now run:");
		Sys.println("  aedifex profiles --json");
		Sys.println("  aedifex build windows . --profile debug");
	}

	public static function remove(targetDirectory:String):Void {
		var removed = false;
		for (entry in buildEntries()) {
			var targetPath = Path.join([targetDirectory, entry.name]);
			if (!FileSystem.exists(targetPath)) continue;
			FileSystem.deleteFile(targetPath);
			Sys.println("Removed " + targetPath);
			removed = true;
		}

		if (!removed) {
			Sys.println("No Aedifex CLI shims were installed in " + targetDirectory + ".");
		}
	}

	public static function printStatus(targetDirectory:String):Void {
		Sys.println("Aedifex CLI target directory: " + targetDirectory);
		for (entry in buildEntries()) {
			var targetPath = Path.join([targetDirectory, entry.name]);
			Sys.println("  " + entry.name + ": " + (FileSystem.exists(targetPath) ? "installed" : "missing"));
		}
		var root = try ToolEnvironment.getAedifexRoot() catch (_:Dynamic) null;
		Sys.println("  active-root: " + (root != null ? root : "unresolved"));
	}

	public static function buildEntries():Array<CliSetupEntry> {
		var unixScript = "#!/bin/sh\n"
			+ "AEDIFEX_PATH=$(haxelib libpath " + CLI_NAME + " 2>/dev/null)\n"
			+ "if [ -z \"$AEDIFEX_PATH\" ]; then\n"
			+ "  echo \"Unable to resolve the aedifex haxelib path.\" >&2\n"
			+ "  exit 1\n"
			+ "fi\n"
			+ "if [ -f \"$AEDIFEX_PATH/run.n\" ]; then\n"
			+ "  AEDIFEX_ROOT=\"$AEDIFEX_PATH\" exec neko \"$AEDIFEX_PATH/run.n\" \"$@\"\n"
			+ "fi\n"
			+ "echo \"Unable to find a runnable Aedifex install. Expected run.n under $AEDIFEX_PATH.\" >&2\n"
			+ "exit 1\n";

		var entries:Array<CliSetupEntry> = [{
			name: CLI_NAME,
			content: unixScript,
			executable: !isWindowsHost()
		}];

		if (isWindowsHost()) {
			var windowsScript = "@echo off\r\n"
				+ "setlocal\r\n"
				+ "set \"AEDIFEX_PATH=\"\r\n"
				+ "for /f \"usebackq delims=\" %%i in (`haxelib libpath " + CLI_NAME + " 2^>nul`) do set \"AEDIFEX_PATH=%%i\"\r\n"
				+ "if not defined AEDIFEX_PATH (\r\n"
				+ "  echo Unable to resolve the aedifex haxelib path.\r\n"
				+ "  exit /b 1\r\n"
				+ ")\r\n"
				+ "if exist \"%AEDIFEX_PATH%\\run.n\" (\r\n"
				+ "  set \"AEDIFEX_ROOT=%AEDIFEX_PATH%\"\r\n"
				+ "  neko \"%AEDIFEX_PATH%\\run.n\" %*\r\n"
				+ "  exit /b %ERRORLEVEL%\r\n"
				+ ")\r\n"
				+ "echo Unable to find a runnable Aedifex install. Expected run.n under %AEDIFEX_PATH%.\r\n"
				+ "exit /b 1\r\n";
			entries.push({
				name: CLI_NAME + ".cmd",
				content: windowsScript,
				executable: false
			});
			entries.push({
				name: CLI_NAME + ".bat",
				content: windowsScript,
				executable: false
			});
		}

		return entries;
	}

	private static function normalizeAction(args:Array<String>):String {
		if (args == null || args.length == 0) return "install";
		var value = StringTools.trim(args[0]).toLowerCase();
		return switch (value) {
			case "remove", "uninstall", "--remove", "--uninstall":
				"remove";
			case "status", "--status":
				"status";
			default:
				"install";
		};
	}

	private static function resolveHaxeRoot():String {
		var programPath = try FileSystem.fullPath(Sys.programPath()) catch (_:Dynamic) Sys.programPath();
		if (programPath != null && programPath.length > 0) {
			var directory = Path.directory(programPath);
			if (directory != null && directory.length > 0) {
				var haxeExecutable = Path.join([directory, executableName("haxe")]);
				var haxelibExecutable = Path.join([directory, executableName("haxelib")]);
				if (FileSystem.exists(haxeExecutable) || FileSystem.exists(haxelibExecutable)) {
					return directory;
				}
			}
		}

		var haxelibConfig = try captureSingleLine("haxelib", ["config"]) catch (_:Dynamic) null;
		if (haxelibConfig != null && haxelibConfig.length > 0) {
			var normalized = StringTools.replace(haxelibConfig, "\\", "/");
			while (normalized.length > 0 && StringTools.endsWith(normalized, "/")) {
				normalized = normalized.substr(0, normalized.length - 1);
			}
			if (StringTools.endsWith(normalized, "/lib")) {
				normalized = normalized.substr(0, normalized.length - 4);
			}
			return normalized;
		}

		throw "Unable to determine the local Haxe tool directory.";
	}

	private static function executableName(base:String):String {
		return isWindowsHost() ? base + ".exe" : base;
	}

	private static function isWindowsHost():Bool {
		return Sys.systemName().toLowerCase() == "windows";
	}

	private static function ensureDirectoryWritable(path:String):Void {
		if (!FileSystem.exists(path) || !FileSystem.isDirectory(path)) {
			throw "Aedifex setup expected a writable Haxe tool directory, but found `" + path + "`.";
		}
	}

	private static function writeIfChanged(path:String, content:String):Void {
		var previous = try File.getContent(path) catch (_:Dynamic) null;
		if (previous == content) return;
		File.saveContent(path, content);
	}

	private static function ensureExecutable(path:String):Void {
		if (isWindowsHost()) return;
		try {
			Sys.command("chmod", ["+x", path]);
		} catch (_:Dynamic) {}
	}

	private static function captureSingleLine(command:String, args:Array<String>):String {
		var process = new Process(command, args);
		try {
			var output = StringTools.trim(process.stdout.readAll().toString());
			process.close();
			return output;
		} catch (error:Dynamic) {
			try process.close() catch (_:Dynamic) {}
			throw error;
		}
	}

	private static function maybeRegisterCurrentCheckout():Void {
		var checkoutRoot = detectCurrentCheckoutRoot();
		if (checkoutRoot == null) return;

		var process = new Process("haxelib", ["dev", CLI_NAME, checkoutRoot]);
		try {
			var stdout = StringTools.trim(process.stdout.readAll().toString());
			var stderr = StringTools.trim(process.stderr.readAll().toString());
			var exitCode = process.exitCode();
			process.close();
			if (exitCode != 0) {
				Sys.println("Warning: failed to register the current Aedifex checkout with haxelib.");
				if (stderr.length > 0) Sys.println(stderr);
				return;
			}

			if (stdout.length > 0) Sys.println(stdout);
			Sys.println("Registered current checkout for `haxelib run aedifex`.");
		} catch (error:Dynamic) {
			try process.close() catch (_:Dynamic) {}
			Sys.println("Warning: unable to register the current Aedifex checkout with haxelib: " + Std.string(error));
		}
	}

	private static function detectCurrentCheckoutRoot():String {
		var cwd = FileSystem.fullPath(Sys.getCwd());
		var gitDir = Path.join([cwd, ".git"]);
		var haxelibJsonPath = Path.join([cwd, "haxelib.json"]);
		var runPath = Path.join([cwd, "src", "aedifex", "cli", "Main.hx"]);
		if (!FileSystem.exists(gitDir) || !FileSystem.exists(haxelibJsonPath) || !FileSystem.exists(runPath)) return null;

		try {
			var data:Dynamic = haxe.Json.parse(File.getContent(haxelibJsonPath));
			return data != null && Reflect.field(data, "name") == CLI_NAME ? cwd : null;
		} catch (_:Dynamic) {
			return null;
		}
	}
}

private typedef CliSetupEntry = {
	var name:String;
	var content:String;
	var executable:Bool;
}
