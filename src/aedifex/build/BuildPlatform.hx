package aedifex.build;

import aedifex.util.SystemUtil;

/**
 * Qualifier and host-environment catalog for Aedifex targets.
 *
 * Desktop host platforms are usually implicit in the CLI, while explicit
 * qualifiers such as `android`, `ios`, `html5`, and `node` are used when
 * the environment must be stated directly.
 */
abstract BuildPlatform(String) from String to String {
	/** Windows desktop host platform. */
	public static inline final WINDOWS:BuildPlatform = "windows";
	/** macOS desktop host platform. */
	public static inline final MAC:BuildPlatform = "mac";
	/** Linux desktop host platform. */
	public static inline final LINUX:BuildPlatform = "linux";
	/** Android qualifier. */
	public static inline final ANDROID:BuildPlatform = "android";
	/** iOS qualifier. */
	public static inline final IOS:BuildPlatform = "ios";
	/** Browser/HTML5 qualifier. */
	public static inline final HTML5:BuildPlatform = "html5";
	/** Node.js qualifier. */
	public static inline final NODE:BuildPlatform = "node";

	/**
	 * Resolves the current host desktop platform.
	 * @return The canonical platform token for the current machine.
	 */
	public static function hostNative():BuildPlatform {
		return switch (SystemUtil.hostPlatform()) {
			case "windows": WINDOWS;
			case "mac": MAC;
			default: LINUX;
		};
	}

	/**
	 * Normalizes user input and accepted aliases into one canonical platform token.
	 * @param value User-facing platform or qualifier text such as `android`, `node`, or `html5`.
	 * @return The canonical `BuildPlatform` value used by the planner.
	 */
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

	/**
	 * Returns all known platform and qualifier tokens.
	 * @return Ordered list of known platforms and qualifiers.
	 */
	public static function allKnown():Array<BuildPlatform> {
		return [WINDOWS, MAC, LINUX, ANDROID, IOS, HTML5, NODE];
	}

	/**
	 * Returns true when this value is one of the native desktop host platforms.
	 * @return `true` for `windows`, `mac`, or `linux`.
	 */
	public inline function isNativeHostPlatform():Bool {
		return this == WINDOWS || this == MAC || this == LINUX;
	}
}
