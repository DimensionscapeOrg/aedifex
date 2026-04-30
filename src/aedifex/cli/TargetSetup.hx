package aedifex.cli;

import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.build.ResolvedBackend;
import aedifex.build.internal.ExecutionPlanner;
import aedifex.util.SystemUtil;
import sys.io.Process;

class TargetSetup {
	public static function run(target:BuildTarget, platform:BuildPlatform):Void {
		var backend = ExecutionPlanner.resolveBackend(target);
		Sys.println("Setting up `" + Std.string(target) + "`" + (platform != null ? " for `" + Std.string(platform) + "`" : "") + "...");

		switch (backend) {
			case ResolvedBackend.CPP:
				ensureHaxelib("hxcpp");
				setupCpp(platform);
			case ResolvedBackend.JVM:
				ensureHaxelib("hxjava");
				requireCommand("java", "Install a Java runtime or JDK so JVM targets can run.");
			case ResolvedBackend.JS:
				if (platform == BuildPlatform.NODE) {
					requireCommand("node", "Install Node.js so js -node targets can run.");
				}
			case ResolvedBackend.HL:
				requireCommand("hl", "Install HashLink so HL targets can run locally.");
			case ResolvedBackend.NEKO:
				requireCommand("neko", "Install Neko so neko targets can run locally.");
			case ResolvedBackend.PHP:
				requireCommand("php", "Install PHP so php targets can run locally.");
			default:
		}

		Sys.println("Setup complete.");
	}

	private static function setupCpp(platform:BuildPlatform):Void {
		switch (SystemUtil.hostPlatform()) {
			case "windows":
				if (!hasCommand("cl")) {
					Sys.println("C++ compiler not detected.");
					Sys.println("Install Visual Studio Build Tools with the Desktop development with C++ workload.");
				} else {
					Sys.println("Detected MSVC toolchain.");
				}
			case "mac":
				if (!hasCommand("clang")) {
					Sys.println("C++ compiler not detected.");
					Sys.println("Install Xcode Command Line Tools so cpp targets can compile.");
				} else {
					Sys.println("Detected clang toolchain.");
				}
			default:
				if (!hasCommand("clang") && !hasCommand("g++")) {
					Sys.println("C++ compiler not detected.");
					Sys.println("Install clang or g++ so cpp targets can compile.");
				} else {
					Sys.println("Detected native C++ toolchain.");
				}
		}

		if (platform == BuildPlatform.ANDROID) {
			Sys.println("Android setup usually needs an SDK/NDK and is best completed by a framework or project setup task.");
		} else if (platform == BuildPlatform.IOS) {
			Sys.println("iOS setup usually needs Xcode signing/toolchain configuration and is best completed by a framework or project setup task.");
		}
	}

	private static function ensureHaxelib(name:String):Void {
		if (hasHaxelib(name)) {
			Sys.println("Detected haxelib `" + name + "`.");
			return;
		}

		Sys.println("Installing haxelib `" + name + "`...");
		var code = Sys.command("haxelib", ["install", name]);
		if (code != 0) {
			throw "Failed to install haxelib `" + name + "`.";
		}
	}

	private static function hasHaxelib(name:String):Bool {
		var process = new Process("haxelib", ["path", name]);
		try {
			process.stdout.readAll();
			var stderr = StringTools.trim(process.stderr.readAll().toString());
			var exitCode = process.exitCode();
			process.close();
			if (exitCode != 0) {
				return false;
			}
			return stderr.indexOf("Library " + name + " is not installed") == -1;
		} catch (_:Dynamic) {
			try process.close() catch (_:Dynamic) {}
			return false;
		}
	}

	private static function requireCommand(command:String, guidance:String):Void {
		if (hasCommand(command)) {
			Sys.println("Detected `" + command + "`.");
			return;
		}

		Sys.println(guidance);
	}

	private static function hasCommand(command:String):Bool {
		var lookup = SystemUtil.hostPlatform() == "windows" ? "where" : "which";
		var process = new Process(lookup, [command]);
		try {
			process.stdout.readAll();
			process.stderr.readAll();
			var exitCode = process.exitCode();
			process.close();
			return exitCode == 0;
		} catch (_:Dynamic) {
			try process.close() catch (_:Dynamic) {}
			return false;
		}
	}
}
