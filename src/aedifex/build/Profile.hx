package aedifex.build;

abstract Profile(String) from String to String {
	public static inline final DEBUG:Profile = "debug";
	public static inline final RELEASE:Profile = "release";
	public static inline final FINAL:Profile = "final";

	public static function normalize(value:String):Profile {
		if (value == null || StringTools.trim(value).length == 0) {
			return RELEASE;
		}

		return switch (StringTools.trim(value).toLowerCase()) {
			case "debug": DEBUG;
			case "release": RELEASE;
			case "final": FINAL;
			default: throw 'Unknown profile: $value';
		};
	}

	public static function all():Array<Profile> {
		return [DEBUG, RELEASE, FINAL];
	}
}
