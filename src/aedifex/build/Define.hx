package aedifex.build;

@:structInit
class Define {
	public var name:String = "";
	public var value:String = null;
	public var condition:BuildCondition = null;

	public function new() {}

	public static function named(name:String, ?value:String, ?condition:BuildCondition):Define {
		var define = new Define();
		define.name = name;
		define.value = value;
		define.condition = BuildCondition.clone(condition);
		return define;
	}

	public static function custom(name:String, ?value:String, ?condition:BuildCondition):Define {
		return named(name, value, condition);
	}

	public static function token(token:String, ?value:String, ?condition:BuildCondition):Define {
		return named(token, value, condition);
	}

	public static function debug(?condition:BuildCondition):Define {
		return named(Defines.DEBUG, null, condition);
	}
}
