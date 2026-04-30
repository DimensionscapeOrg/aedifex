package aedifex.build;

/**
 * Architecture catalog for target resolution.
 *
 * Aedifex defaults to the most common architecture for the selected target,
 * but projects and command-line invocations can override it explicitly.
 */
abstract BuildArchitecture(String) from String to String {
	/** 32-bit x86. */
	public static inline final X86:BuildArchitecture = "x86";
	/** 64-bit x86. */
	public static inline final X64:BuildArchitecture = "x64";
	/** 64-bit ARM. */
	public static inline final ARM64:BuildArchitecture = "arm64";
	/** 32-bit ARM v7. */
	public static inline final ARMV7:BuildArchitecture = "armv7";

	/**
	 * Returns the default architecture used when none is specified explicitly.
	 * @return The default architecture token.
	 */
	public static function hostDefault():BuildArchitecture {
		return X64;
	}

	/**
	 * Normalizes user input and accepted aliases into one canonical architecture token.
	 * @param value User-facing architecture text such as `x64` or `arm64`.
	 * @return The canonical architecture token.
	 */
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

	/**
	 * Returns all known architecture tokens.
	 * @return Ordered list of supported architecture tokens.
	 */
	public static function allKnown():Array<BuildArchitecture> {
		return [X86, X64, ARM64, ARMV7];
	}
}
