package aedifex.build;

import aedifex.util.SystemUtil;

abstract BuildPlatform(String) from String to String {
	public static inline final WINDOWS:BuildPlatform = "windows";
	public static inline final MAC:BuildPlatform = "mac";
	public static inline final LINUX:BuildPlatform = "linux";
	public static inline final ANDROID:BuildPlatform = "android";
	public static inline final IOS:BuildPlatform = "ios";
	public static inline final HTML5:BuildPlatform = "html5";
	public static inline final NODE:BuildPlatform = "node";

	public static function hostNative():BuildPlatform {
		return switch (SystemUtil.hostPlatform()) {
			case "windows": WINDOWS;
			case "mac": MAC;
			default: LINUX;
		};
	}

	public static function normalize(value:String):BuildPlatform {
		if (value == null) {
			throw "Missing platform";
		}

		var normalized = StringTools.trim(value).toLowerCase();
		if (StringTools.startsWith(normalized, "-")) {
			normalized = normalized.substr(1);
		}

		return switch (normalized) {
			case "windows", "win": WINDOWS;
			case "mac", "macos", "osx": MAC;
			case "linux": LINUX;
			case "android": ANDROID;
			case "ios": IOS;
			case "html5", "web", "browser": HTML5;
			case "node", "nodejs": NODE;
			default: throw 'Unknown platform: $value';
		};
	}

	public static function allKnown():Array<BuildPlatform> {
		return [WINDOWS, MAC, LINUX, ANDROID, IOS, HTML5, NODE];
	}

	public inline function isNativeHostPlatform():Bool {
		return this == WINDOWS || this == MAC || this == LINUX;
	}
}
