package aedifex.build;

@:structInit
class BuildCondition {
	public var ifTokens:Array<String> = [];
	public var unlessTokens:Array<String> = [];

	public function new() {}

	public static function when(token:String):BuildCondition {
		var condition = new BuildCondition();
		condition.ifTokens.push(cast token);
		return condition;
	}

	public static function whenAll(tokens:Array<String>):BuildCondition {
		var condition = new BuildCondition();
		condition.ifTokens = normalizeInputs(tokens);
		return condition;
	}

	public static function unless(token:String):BuildCondition {
		var condition = new BuildCondition();
		condition.unlessTokens.push(cast token);
		return condition;
	}

	public static function unlessAny(tokens:Array<String>):BuildCondition {
		var condition = new BuildCondition();
		condition.unlessTokens = normalizeInputs(tokens);
		return condition;
	}

	public static function both(?ifTokens:Array<String>, ?unlessTokens:Array<String>):BuildCondition {
		var condition = new BuildCondition();
		condition.ifTokens = normalizeInputs(ifTokens);
		condition.unlessTokens = normalizeInputs(unlessTokens);
		return condition;
	}

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

	public static function clone(value:BuildCondition):BuildCondition {
		if (value == null) return null;
		var condition = new BuildCondition();
		condition.ifTokens = normalizeTokens(value.ifTokens);
		condition.unlessTokens = normalizeTokens(value.unlessTokens);
		return condition;
	}

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
