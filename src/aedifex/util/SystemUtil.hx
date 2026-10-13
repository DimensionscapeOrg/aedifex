package aedifex.util;

import sys.io.Process;

/**
 * ...
 * @author Christopher Speciale
 */
class SystemUtil {
	public static var platform(get, never):String;

	private static var cachedArchitecture:String = null;

	public static inline function hostPlatform():String {
		return switch (Sys.systemName().toLowerCase()) {
			case "windows": "windows";
			case "mac", "macos": "mac";
			default: "linux";
		};
	}

	/**
	 * Returns the architecture of the machine Aedifex runs on: `x86`, `x64`, `arm64` or `armv7`.
	 */
	public static function hostArchitecture():String {
		if (cachedArchitecture == null) {
			cachedArchitecture = detectArchitecture();
		}
		return cachedArchitecture;
	}

	private static function detectArchitecture():String {
		if (Sys.systemName() == "Windows") {
			// A 32-bit process on 64-bit Windows sees x86 in PROCESSOR_ARCHITECTURE and the machine's
			// architecture in PROCESSOR_ARCHITEW6432.
			var name = Sys.getEnv("PROCESSOR_ARCHITEW6432");
			if (name == null || StringTools.trim(name).length == 0) {
				name = Sys.getEnv("PROCESSOR_ARCHITECTURE");
			}
			return normalizeArchitecture(name);
		}
		// Apple silicon answers 1 even to a process running under Rosetta, for which uname reports x86_64.
		if (Sys.systemName() == "Mac" && commandOutput("sysctl", ["-n", "hw.optional.arm64"]) == "1") {
			return "arm64";
		}
		return normalizeArchitecture(commandOutput("uname", ["-m"]));
	}

	private static function normalizeArchitecture(name:String):String {
		if (name == null) return "x64";
		return switch (StringTools.trim(name).toLowerCase()) {
			case "x86", "i386", "i686", "ia32": "x86";
			case "amd64", "x86_64", "x64": "x64";
			case "arm64", "aarch64": "arm64";
			case "arm", "armv7", "armv7l": "armv7";
			default: "x64";
		};
	}

	private static function commandOutput(command:String, args:Array<String>):String {
		try {
			var process = new Process(command, args);
			var output = process.stdout.readAll().toString();
			process.exitCode();
			process.close();
			return StringTools.trim(output);
		} catch (_:Dynamic) {
			return null;
		}
	}

	private static inline function get_platform():String {
		return Sys.systemName().toLowerCase();
	}
}
