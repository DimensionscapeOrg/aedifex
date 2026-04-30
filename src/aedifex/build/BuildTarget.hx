package aedifex.build;

/**
 * Public target catalog for Aedifex build, run, test, and setup commands.
 *
 * Targets are target-first. Host desktop is implicit, while non-default
 * environments are expressed through qualifiers such as `node` or `android`.
 */
abstract BuildTarget(String) from String to String {
	/** Native/cpp target for the current host desktop or a qualified environment. */
	public static inline final CPP:BuildTarget = "cpp";
	/** HashLink target. */
	public static inline final HL:BuildTarget = "hl";
	/** Neko target. */
	public static inline final NEKO:BuildTarget = "neko";
	/** JVM bytecode target. */
	public static inline final JVM:BuildTarget = "jvm";
	/** PHP target. */
	public static inline final PHP:BuildTarget = "php";
	/** JavaScript target. Pair with `html5` or `node` when needed. */
	public static inline final JS:BuildTarget = "js";

	/**
	 * Normalizes user input and accepted aliases into one canonical build target.
	 * @param value User-facing target text such as `cpp`, `js`, `native`, or `jvm`.
	 * @return The canonical `BuildTarget` value used by the planner.
	 */
	public static function normalize(value:String):BuildTarget {
		if (value == null) {
			throw "Missing target";
		}

		var normalized = StringTools.trim(value).toLowerCase();
		if (StringTools.startsWith(normalized, "-")) {
			normalized = normalized.substr(1);
		}

		return switch (normalized) {
			case "cpp", "native": CPP;
			case "hl", "hashlink": HL;
			case "neko": NEKO;
			case "java", "jvm", "jar": JVM;
			case "php": PHP;
			case "js", "javascript": JS;
			default: throw 'Unknown target: $value';
		};
	}

	/**
	 * Returns the public targets that should be shown in help and tooling.
	 * @return Ordered list of public targets.
	 */
	public static function allPublic():Array<BuildTarget> {
		return [CPP, HL, NEKO, JVM, PHP, JS];
	}

	/**
	 * Returns all currently recognized targets.
	 * @return Ordered list of all known targets.
	 */
	public static function allKnown():Array<BuildTarget> {
		return [CPP, HL, NEKO, JVM, PHP, JS];
	}
}
