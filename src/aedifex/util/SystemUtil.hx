package aedifex.util;

/**
 * ...
 * @author Christopher Speciale
 */
class SystemUtil {
	public static var platform(get, never):String;

	public static inline function hostPlatform():String {
		return switch (Sys.systemName().toLowerCase()) {
			case "windows": "windows";
			case "mac", "macos": "mac";
			default: "linux";
		};
	}

	public static function hostArchitecture():String {
		var candidates = [
			Sys.getEnv("PROCESSOR_ARCHITECTURE"),
			Sys.getEnv("PROCESSOR_ARCHITEW6432"),
			Sys.getEnv("HOSTTYPE"),
			Sys.getEnv("MACHTYPE")
		];
		for (candidate in candidates) {
			if (candidate == null) continue;
			var normalized = StringTools.trim(candidate).toLowerCase();
			if (normalized.length == 0) continue;
			return switch (normalized) {
				case "x86", "i386", "i686", "ia32": "x86";
				case "amd64", "x86_64", "x64": "x64";
				case "arm64", "aarch64": "arm64";
				case "arm", "armv7", "armv7l": "armv7";
				default: "x64";
			};
		}
		return "x64";
	}

	private static inline function get_platform():String {
		return Sys.systemName().toLowerCase();
	}
}
