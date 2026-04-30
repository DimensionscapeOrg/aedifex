package aedifex.build;

abstract BuildTarget(String) from String to String {
	public static inline final CPP:BuildTarget = "cpp";
	public static inline final HL:BuildTarget = "hl";
	public static inline final NEKO:BuildTarget = "neko";
	public static inline final JVM:BuildTarget = "jvm";
	public static inline final PHP:BuildTarget = "php";
	public static inline final JS:BuildTarget = "js";

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

	public static function allPublic():Array<BuildTarget> {
		return [CPP, HL, NEKO, JVM, PHP, JS];
	}

	public static function allKnown():Array<BuildTarget> {
		return [CPP, HL, NEKO, JVM, PHP, JS];
	}
}
