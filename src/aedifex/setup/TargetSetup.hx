package aedifex.setup;

import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.util.SystemUtil;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;

class TargetSetup {
	public static function inspect(target:BuildTarget, ?platform:BuildPlatform):SetupStatus {
		return evaluate(target, platform, true);
	}

	public static function run(target:BuildTarget, ?platform:BuildPlatform, checkOnly:Bool = false):SetupStatus {
		return evaluate(target, platform, checkOnly);
	}

	public static function defaultPlatform(target:BuildTarget):BuildPlatform {
		return switch (target) {
			case BuildTarget.JS: BuildPlatform.HTML5;
			default: BuildPlatform.hostNative();
		};
	}

	public static function explicitQualifiers(target:BuildTarget):Array<BuildPlatform> {
		return switch (target) {
			case BuildTarget.CPP: [BuildPlatform.ANDROID, BuildPlatform.IOS];
			case BuildTarget.JS: [BuildPlatform.HTML5, BuildPlatform.NODE];
			default: [];
		};
	}

	public static function isPlatformAllowed(target:BuildTarget, platform:BuildPlatform):Bool {
		if (platform == null) {
			return true;
		}

		return switch (target) {
			case BuildTarget.CPP:
				platform == BuildPlatform.hostNative() || platform == BuildPlatform.ANDROID || platform == BuildPlatform.IOS;
			case BuildTarget.HL, BuildTarget.NEKO, BuildTarget.JVM, BuildTarget.PHP:
				platform == BuildPlatform.hostNative();
			case BuildTarget.JS:
				platform == BuildPlatform.HTML5 || platform == BuildPlatform.NODE;
			default:
				false;
		};
	}

	public static function setupCommand(target:BuildTarget, ?platform:BuildPlatform):String {
		var effectivePlatform = effectivePlatform(target, platform);
		var base = "aedifex setup " + Std.string(target);
		return switch (effectivePlatform) {
			case BuildPlatform.ANDROID: base + " -android";
			case BuildPlatform.IOS: base + " -ios";
			case BuildPlatform.HTML5: base;
			case BuildPlatform.NODE: base + " -node";
			default: base;
		};
	}

	private static function evaluate(target:BuildTarget, ?platform:BuildPlatform, checkOnly:Bool):SetupStatus {
		var effectivePlatform = effectivePlatform(target, platform);
		if (!isPlatformAllowed(target, effectivePlatform)) {
			throw 'Platform `${effectivePlatform}` is not valid for target `${target}`.';
		}

		var status = new SetupStatus(target, effectivePlatform, setupCommand(target, effectivePlatform));

		switch (target) {
			case BuildTarget.CPP:
				ensureHaxelib("hxcpp", status, checkOnly);
				checkCpp(status);
			case BuildTarget.HL:
				requireCommand("hl", "HashLink", "Install HashLink so hl targets can build and run on this machine.", status);
			case BuildTarget.NEKO:
				requireCommand("neko", "Neko", "Install Neko so neko targets can build and run on this machine.", status);
			case BuildTarget.JVM:
				ensureHaxelib("hxjava", status, checkOnly);
				requireCommand("java", "Java", "Install a Java runtime or JDK so jvm targets can build and run on this machine.", status);
			case BuildTarget.PHP:
				requireCommand("php", "PHP", "Install PHP so php targets can build and run on this machine.", status);
			case BuildTarget.JS:
				if (effectivePlatform == BuildPlatform.NODE) {
					requireCommand("node", "Node.js", "Install Node.js so js -node targets can build and run on this machine.", status);
				} else {
					rememberDetected("HTML5 browser environment", status);
				}
		}

		return status.finalize();
	}

	private static function checkCpp(status:SetupStatus):Void {
		switch (status.platform) {
			case BuildPlatform.ANDROID:
				rememberMissing("android provider", status);
				rememberStep("Android setup in core Aedifex is not fully automated yet. Use a framework/provider that owns the Android SDK and NDK toolchain.", status);
				return;
			case BuildPlatform.IOS:
				rememberMissing("ios provider", status);
				rememberStep("iOS setup in core Aedifex is not fully automated yet. Use a framework/provider that owns Xcode signing and the iOS toolchain.", status);
				return;
			default:
		}

		switch (SystemUtil.hostPlatform()) {
			case "windows":
				if (hasCommand("cl")) {
					rememberDetected("MSVC", status);
				} else {
					rememberMissing("c++ compiler", status);
					rememberStep("Install Visual Studio Build Tools with the Desktop development with C++ workload.", status);
				}
			case "mac":
				if (hasCommand("clang")) {
					rememberDetected("clang", status);
				} else {
					rememberMissing("c++ compiler", status);
					rememberStep("Install Xcode Command Line Tools so cpp targets can compile.", status);
				}
			default:
				if (hasCommand("clang")) {
					rememberDetected("clang", status);
				} else if (hasCommand("g++")) {
					rememberDetected("g++", status);
				} else {
					rememberMissing("c++ compiler", status);
					rememberStep("Install clang or g++ so cpp targets can compile.", status);
				}
		}
	}

	private static function effectivePlatform(target:BuildTarget, platform:BuildPlatform):BuildPlatform {
		return platform != null ? platform : defaultPlatform(target);
	}

	private static function ensureHaxelib(name:String, status:SetupStatus, checkOnly:Bool):Void {
		if (hasHaxelib(name)) {
			rememberDetected(name, status);
			return;
		}

		if (checkOnly) {
			rememberMissing(name, status);
			rememberStep("Install haxelib `" + name + "` by running `" + status.setupCommand + "`.", status);
			return;
		}

		var code = Sys.command("haxelib", ["install", name]);
		if (code == 0 && hasHaxelib(name)) {
			rememberInstalled(name, status);
			return;
		}

		rememberMissing(name, status);
		rememberStep("Failed to install haxelib `" + name + "`. Install it manually, then rerun `" + status.setupCommand + "`.", status);
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

	private static function requireCommand(command:String, label:String, guidance:String, status:SetupStatus):Void {
		if (hasCommand(command)) {
			rememberDetected(label, status);
			return;
		}

		rememberMissing(command, status);
		rememberStep(guidance, status);
	}

	private static function hasCommand(command:String):Bool {
		if (command == null) return false;
		var trimmed = StringTools.trim(command);
		if (trimmed.length == 0) return false;
		if (canStartCommand(trimmed)) return true;
		if (hasCommandViaSystemLookup(trimmed)) return true;

		var candidates = commandCandidates(trimmed);
		if (trimmed.indexOf("/") != -1 || trimmed.indexOf("\\") != -1 || Path.isAbsolute(trimmed)) {
			for (candidate in candidates) {
				if (isFile(candidate)) return true;
			}
			return false;
		}

		var pathValue = Sys.getEnv("PATH");
		if (pathValue == null || pathValue.length == 0) {
			return false;
		}

		var separator = SystemUtil.hostPlatform() == "windows" ? ";" : ":";
		for (directory in pathValue.split(separator)) {
			var normalized = StringTools.trim(directory);
			if (normalized.length == 0) continue;
			for (candidate in candidates) {
				if (isFile(Path.join([normalized, candidate]))) {
					return true;
				}
			}
		}

		return false;
	}

	private static function canStartCommand(command:String):Bool {
		try {
			var probe = shellProbe(command, probeArgs(command));
			return if (SystemUtil.hostPlatform() == "windows") {
				Sys.command("cmd", ["/c", probe]) == 0;
			} else {
				Sys.command("sh", ["-lc", probe]) == 0;
			};
		} catch (_:Dynamic) {
			return false;
		}
	}

	private static function hasCommandViaSystemLookup(command:String):Bool {
		var process = try {
			new Process(SystemUtil.hostPlatform() == "windows" ? "where" : "which", [command]);
		} catch (_:Dynamic) {
			return false;
		}

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

	private static function commandCandidates(command:String):Array<String> {
		var candidates = [command];
		if (SystemUtil.hostPlatform() == "windows" && (Path.extension(command) == null || Path.extension(command).length == 0)) {
			var extValue = Sys.getEnv("PATHEXT");
			var extensions = extValue != null && extValue.length > 0 ? extValue.split(";") : [".EXE", ".BAT", ".CMD", ".COM"];
			for (extension in extensions) {
				var normalized = StringTools.trim(extension);
				if (normalized.length == 0) continue;
				var suffix = StringTools.startsWith(normalized, ".") ? normalized : "." + normalized;
				var lower = command + suffix.toLowerCase();
				if (candidates.indexOf(lower) == -1) candidates.push(lower);
				var upper = command + suffix.toUpperCase();
				if (candidates.indexOf(upper) == -1) candidates.push(upper);
			}
		}
		return candidates;
	}

	private static function probeArgs(command:String):Array<String> {
		return switch (command.toLowerCase()) {
			case "java": ["-version"];
			case "node": ["--version"];
			case "php": ["-v"];
			case "neko": ["-version"];
			case "hl": ["--version"];
			case "cl": ["/?"];
			case "clang", "g++": ["--version"];
			default: ["--version"];
		};
	}

	private static function shellProbe(command:String, args:Array<String>):String {
		var parts = [quoteShellArg(command)];
		for (arg in args) {
			parts.push(quoteShellArg(arg));
		}
		return if (SystemUtil.hostPlatform() == "windows") {
			parts.join(" ") + " >NUL 2>NUL";
		} else {
			parts.join(" ") + " >/dev/null 2>&1";
		};
	}

	private static function quoteShellArg(value:String):String {
		return if (SystemUtil.hostPlatform() == "windows") {
			'"' + StringTools.replace(value, '"', '""') + '"';
		} else {
			"'" + StringTools.replace(value, "'", "'\\''") + "'";
		};
	}

	private static function isFile(path:String):Bool {
		return FileSystem.exists(path) && !FileSystem.isDirectory(path);
	}

	private static function rememberInstalled(value:String, status:SetupStatus):Void {
		if (status.installed.indexOf(value) == -1) status.installed.push(value);
	}

	private static function rememberDetected(value:String, status:SetupStatus):Void {
		if (status.detected.indexOf(value) == -1) status.detected.push(value);
	}

	private static function rememberMissing(value:String, status:SetupStatus):Void {
		if (status.missing.indexOf(value) == -1) status.missing.push(value);
	}

	private static function rememberStep(value:String, status:SetupStatus):Void {
		if (status.manualSteps.indexOf(value) == -1) status.manualSteps.push(value);
	}
}
