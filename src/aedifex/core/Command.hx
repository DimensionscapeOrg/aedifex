package aedifex.core;

class Command {
	public var args:Array<String> = [];

	public function new() {}

	public inline function add(x:String):Void {
		args.push(x);
	}

	public inline function addMany(xs:Array<String>):Void {
		for (x in xs) {
			args.push(x);
		}
	}

	public function run():Int {
		var exe:String = args.shift();
		if (args.length == 0) {
			return Sys.command(exe);
		}
		return Sys.command(exe, args);
	}
}
