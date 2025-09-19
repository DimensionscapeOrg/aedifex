package aedifex.plugin;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Bytes;

class PluginWire {
	private inline static final WIRE_PROTOCOL_VERSION:Int = 1;
	// private inline static final MAX_FRAME:Int = 8 * 1024 * 1024;
	private static var IN = Sys.stdin();
	private static var OUT = Sys.stdout();
	private static var ERR = Sys.stderr();

	public static function init() {
		while (true) {
			var call:Call = readCall();

			if (call == null) {
				break;
			}
			var resp:Response = Dispatch.handle(call);

			writeResponse(resp);
		}
	}

	private static function readCall():Null<Call> {
		var len:Int = readInt32();

		if (len <= 0) {
			return null;
		}

		var payload:String = readExact(len);
		try {
			return Unserializer.run(payload);
		} catch (e:Dynamic) {
			writeResponse({error: {code: "PROTO", message: 'Unserialize failed: ' + Std.string(e)}});
			return null;
		}
	}

	private static inline function writeResponse(resp:Response):Void {
		var s:String = Serializer.run(resp);
		writeInt32(s.length);
		OUT.writeString(s);
		OUT.flush();
	}

	private static function readInt32():Int {
		try {
			return IN.readInt32();
		} catch (_:Dynamic) {
			return -1;
		}
	}

	private static inline function writeInt32(n:Int):Void {
		OUT.writeInt32(n);
	}

	private static inline function readExact(len:Int):String {
		var b:Bytes = Bytes.alloc(len);
		var off:Int = 0;
		while (off < len) {
			var n:Int = IN.readBytes(b, off, len - off);
			if (n <= 0) {
				throw "Unexpected EOF";
			}

			off += n;
		}
		return b.toString();
	}
}

typedef Call = {
	var method:String;
	var args:Array<Dynamic>;
}

typedef ErrorObj = {
	var code:String;
	var message:String;
	@:optional var data:Dynamic;
}

typedef Response = {
	@:optional var result:Dynamic;
	@:optional var error:ErrorObj;
}

typedef BuildContext = {
	var projectRoot:String;
	var target:String;
	var profile:String;
	var outDir:String;
	var binDir:String;
	var objDir:String;
	var haxeDir:String;
	@:optional var defines:Array<String>;
	@:optional var libs:Array<String>;
	@:optional var env:Dynamic<String>;
	@:optional var files:Array<String>;
	@:optional var config:Dynamic;
	@:optional var changed:Array<String>;
}

typedef CommandParams = {
	var name:String;
	var argv:Array<String>;
	@:optional var ctx:BuildContext;
}

typedef HandshakeMessage = {
	var ok:Bool;
	var pluginName:String;
	var pluginVersion:String;
	var protocol:Int;
	var capabilities:Array<String>;
	@:optional var reflection:Dynamic;
}

class Handlers {
	public static function pluginInit(params:{hostVersion:String, protocol:Int}):HandshakeMessage {
		return {
			ok: true,
			pluginName: "aedifex-themes",
			pluginVersion: "0.1.0",
			protocol: 1,
			capabilities: [],
			reflection: {}
		};
	}

	public static function preBuild(ctx:BuildContext):Dynamic {
		return {ok: true, messages: [{level: "info", text: "preBuild ok"}]};
	}

	public static function postBuild(ctx:BuildContext):Dynamic {
		return {ok: true};
	}

	public static function commandRun(p:CommandParams):Dynamic {
		return switch (p.name) {
			case "themes:list": {ok: true, themes: ["cyber", "aurora", "red"]};
			default: {ok: false, error: {code: "METHOD_NOT_FOUND", message: 'Unknown command: ${p.name}'}};
		}
	}
}

class Dispatch {
	public static function handle(c:Call):Response {
		try {
			return switch (c.method) {
				case "plugin.init":
					var p = (c.args != null && c.args.length > 0) ? c.args[0] : {hostVersion: "", protocol: 1};
					{result: Handlers.pluginInit(p)};

				case "hook.preBuild":
					final ctx:BuildContext = (c.args != null && c.args.length > 0) ? c.args[0] : null;
					{result: Handlers.preBuild(ctx)};

				case "hook.postBuild":
					final ctx2:BuildContext = (c.args != null && c.args.length > 0) ? c.args[0] : null;
					{result: Handlers.postBuild(ctx2)};

				case "command.run":
					final p2:CommandParams = (c.args != null && c.args.length > 0) ? c.args[0] : {name: "", argv: []};
					{result: Handlers.commandRun(p2)};

				default:
					{error: {code: "METHOD_NOT_FOUND", message: c.method}};
			}
		} catch (e:Dynamic) {
			return {error: {code: "EXCEPTION", message: Std.string(e)}};
		}
	}
}
