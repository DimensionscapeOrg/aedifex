package aedifex.build;

abstract BuildArchitecture(String) from String to String {
	public static inline final X86:BuildArchitecture = "x86";
	public static inline final X64:BuildArchitecture = "x64";
	public static inline final ARM64:BuildArchitecture = "arm64";
	public static inline final ARMV7:BuildArchitecture = "armv7";

	public static function hostDefault():BuildArchitecture {
		return X64;
	}

	public static function normalize(value:String):BuildArchitecture {
		if (value == null) {
			throw "Missing architecture";
		}

		var normalized = StringTools.trim(value).toLowerCase();
		if (StringTools.startsWith(normalized, "-")) {
			normalized = normalized.substr(1);
		}

		return switch (normalized) {
			case "x86", "ia32", "win32": X86;
			case "x64", "amd64", "x86_64": X64;
			case "arm64", "aarch64": ARM64;
			case "armv7", "arm": ARMV7;
			default: throw 'Unknown architecture: $value';
		};
	}

	public static function allKnown():Array<BuildArchitecture> {
		return [X86, X64, ARM64, ARMV7];
	}
}
