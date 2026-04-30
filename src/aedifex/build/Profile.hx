package aedifex.build;

/**
 * Build profile catalog.
 *
 * Profiles describe the build mode rather than the target environment.
 */
abstract Profile(String) from String to String {
	/** Fast iteration profile. */
	public static inline final DEBUG:Profile = "debug";
	/** Standard optimized profile. */
	public static inline final RELEASE:Profile = "release";
	/** Final distribution-oriented profile with finalization hooks. */
	public static inline final FINAL:Profile = "final";

	/**
	 * Normalizes user input into one canonical profile value.
	 * @param value User-facing profile text such as `debug`, `release`, or `final`.
	 * @return The canonical profile. Empty input falls back to `release`.
	 */
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

	/**
	 * Returns the public profile list in display order.
	 * @return Ordered list of public profiles.
	 */
	public static function all():Array<Profile> {
		return [DEBUG, RELEASE, FINAL];
	}
}
