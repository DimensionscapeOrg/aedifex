package aedifex.build;

/**
 * Represents one Haxe define entry in the resolved Aedifex build model.
 *
 * Use this when you want to attach a raw define name/value pair directly,
 * or use the helpers such as `token(...)` and `debug()` for common cases.
 */
@:structInit
class Define {
	/** The emitted define name, for example `debug` or `my_feature`. */
	public var name:String = "";
	/** Optional define value for `-D name=value` style defines. */
	public var value:String = null;
	/** Optional condition controlling when this define is active. */
	public var condition:BuildCondition = null;

	public function new() {}

	/**
	 * Creates a define from a raw name and optional value.
	 * @param name Define name.
	 * @param value Optional define value.
	 * @param condition Optional activation condition.
	 * @return A new define entry.
	 */
	public static function named(name:String, ?value:String, ?condition:BuildCondition):Define {
		var define = new Define();
		define.name = name;
		define.value = value;
		define.condition = BuildCondition.clone(condition);
		return define;
	}

	/**
	 * Alias for `named(...)` when you want to emphasize that the define is project-specific.
	 * @param name Define name.
	 * @param value Optional define value.
	 * @param condition Optional activation condition.
	 * @return A new define entry.
	 */
	public static function custom(name:String, ?value:String, ?condition:BuildCondition):Define {
		return named(name, value, condition);
	}

	/**
	 * Creates a define from a typed token such as `Defines.DEBUG` or `Defines.NODE`.
	 * @param token Typed define token.
	 * @param value Optional define value.
	 * @param condition Optional activation condition.
	 * @return A new define entry.
	 */
	public static function token(token:String, ?value:String, ?condition:BuildCondition):Define {
		return named(token, value, condition);
	}

	/**
	 * Convenience helper for the common `debug` define.
	 * @param condition Optional activation condition.
	 * @return A `debug` define entry.
	 */
	public static function debug(?condition:BuildCondition):Define {
		return named(Defines.DEBUG, null, condition);
	}
}
