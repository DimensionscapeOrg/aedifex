package aedifex.build;

/**
 * Describes when a rule, define, hook, or extension should be active.
 *
 * Conditions are token-based so they compose naturally with `Defines`,
 * targets, qualifiers, architectures, and profiles.
 */
@:structInit
class BuildCondition {
	/** Tokens that must be active for the condition to match. */
	public var ifTokens:Array<String> = [];
	/** Tokens that must not be active for the condition to match. */
	public var unlessTokens:Array<String> = [];

	public function new() {}

	/**
	 * Creates a condition that is active when one token is present.
	 * @param token Required active token.
	 * @return A new condition.
	 */
	public static function when(token:String):BuildCondition {
		var condition = new BuildCondition();
		condition.ifTokens.push(cast token);
		return condition;
	}

	/**
	 * Creates a condition that is active when all listed tokens are present.
	 * @param tokens Required active tokens.
	 * @return A new condition.
	 */
	public static function whenAll(tokens:Array<String>):BuildCondition {
		var condition = new BuildCondition();
		condition.ifTokens = normalizeInputs(tokens);
		return condition;
	}

	/**
	 * Creates a condition that is active when one token is absent.
	 * @param token Forbidden active token.
	 * @return A new condition.
	 */
	public static function unless(token:String):BuildCondition {
		var condition = new BuildCondition();
		condition.unlessTokens.push(cast token);
		return condition;
	}

	/**
	 * Creates a condition that is active when all listed tokens are absent.
	 * @param tokens Forbidden active tokens.
	 * @return A new condition.
	 */
	public static function unlessAny(tokens:Array<String>):BuildCondition {
		var condition = new BuildCondition();
		condition.unlessTokens = normalizeInputs(tokens);
		return condition;
	}

	/**
	 * Creates a condition from explicit positive and negative token lists.
	 * @param ifTokens Tokens that must be present.
	 * @param unlessTokens Tokens that must be absent.
	 * @return A new condition.
	 */
	public static function both(?ifTokens:Array<String>, ?unlessTokens:Array<String>):BuildCondition {
		var condition = new BuildCondition();
		condition.ifTokens = normalizeInputs(ifTokens);
		condition.unlessTokens = normalizeInputs(unlessTokens);
		return condition;
	}

	/**
	 * Combines two conditions into one merged token set.
	 * @param left First condition.
	 * @param right Second condition.
	 * @return A merged condition.
	 */
	public static function combine(left:BuildCondition, right:BuildCondition):BuildCondition {
		if (left == null) return clone(right);
		if (right == null) return clone(left);

		var condition = new BuildCondition();
		condition.ifTokens = normalizeTokens(left.ifTokens);
		for (token in normalizeTokens(right.ifTokens)) {
			if (condition.ifTokens.indexOf(token) == -1) {
				condition.ifTokens.push(token);
			}
		}

		condition.unlessTokens = normalizeTokens(left.unlessTokens);
		for (token in normalizeTokens(right.unlessTokens)) {
			if (condition.unlessTokens.indexOf(token) == -1) {
				condition.unlessTokens.push(token);
			}
		}

		return condition;
	}

	/**
	 * Creates a defensive copy of a condition for storage in the build model.
	 * @param value Condition to copy.
	 * @return A copied condition or `null`.
	 */
	public static function clone(value:BuildCondition):BuildCondition {
		if (value == null) return null;
		var condition = new BuildCondition();
		condition.ifTokens = normalizeTokens(value.ifTokens);
		condition.unlessTokens = normalizeTokens(value.unlessTokens);
		return condition;
	}

	/**
	 * Evaluates a condition against the currently active token map.
	 * @param value Condition to evaluate.
	 * @param activeTokens Map of active tokens.
	 * @return `true` when the condition is satisfied.
	 */
	public static function isActive(value:BuildCondition, activeTokens:Map<String, Bool>):Bool {
		if (value == null) return true;

		for (token in normalizeTokens(value.ifTokens)) {
			if (activeTokens == null || !activeTokens.exists(token)) {
				return false;
			}
		}

		for (token in normalizeTokens(value.unlessTokens)) {
			if (activeTokens != null && activeTokens.exists(token)) {
				return false;
			}
		}

		return true;
	}

	private static function normalizeTokens(tokens:Array<String>):Array<String> {
		var results:Array<String> = [];
		if (tokens == null) return results;

		for (token in tokens) {
			if (token == null) continue;
			var text = Std.string(token);
			if (text.length == 0 || results.indexOf(token) != -1) continue;
			results.push(token);
		}

		return results;
	}

	private static function normalizeInputs(tokens:Array<String>):Array<String> {
		var results:Array<String> = [];
		if (tokens == null) return results;

		for (token in tokens) {
			if (token == null) continue;
			var text = Std.string(token);
			if (text.length == 0) continue;
			if (results.indexOf(text) != -1) continue;
			results.push(text);
		}

		return results;
	}
}
