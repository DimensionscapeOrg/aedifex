package aedifex.plugin;

import haxe.ds.StringMap;
import haxe.Timer;
import haxe.io.Input;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Bytes;
import haxe.io.Path;
import sys.io.Process;
import sys.thread.Deque;
import sys.thread.Thread;
import sys.thread.Mutex;

class Plugin extends Process {
	public inline static final WIRE_PROTOCOL_VERSION:Int = 1;

	public var name(default, null):String;
	public var pluginVersion(default, null):String;
	public var capabilities(default, null):Array<String> = [];

	private var _responses:Deque<PluginResponse> = new Deque();
	private var _reader:Thread;
	private var _errReader:Thread;
	private var _running:Bool = true;

	private var _awaiting:Bool = false;
	private var _awaitingTicket:Int = 0;
	private var _ticketCounter:Int = 0;
	private var _awaitMux:Mutex = new Mutex();
	private var _dropNext:Bool = false;
	private var _ready:Bool = false;

	public function new(path:String) {
		super(path);
		name = Path.withoutDirectory(Path.withoutExtension(path));

		_errReader = Thread.create(() -> {
			try {
				while (_running) {
					Sys.println("[plugin:" + name + "] " + this.stderr.readLine());
				}
			} catch (e:Dynamic) {}
		});

		_reader = Thread.create(() -> {
			try {
				while (_running) {
					var len:Int = safeReadInt32(this.stdout);
					if (len <= 0) {
						Sys.sleep(0.003);
						continue;
					}
					var payload:String = readExact(this.stdout, len);
					var parsed:Dynamic = null;
					try {
						parsed = Unserializer.run(payload);
					} catch (e:Dynamic) {
						pushEnvelope({
							ok: false,
							error: {code: "PROTO", message: 'Unserialize failed: ' + Std.string(e), data: payload},
							result: null
						});
						continue;
					}

					var ok:Bool = true;
					var res:Dynamic = parsed;
					var err:PluginError = null;
					if (Reflect.hasField(parsed, "error") || Reflect.hasField(parsed, "result")) {
						ok = (parsed.error == null);
						res = parsed.result;
						if (!ok) {
							err = {
								code: Std.string(parsed.error.code),
								message: Std.string(parsed.error.message),
								data: Reflect.field(parsed.error, "data")
							};
						}
					}
					if (_dropNext) {
						_dropNext = false;
						continue;
					}
					pushEnvelope({ok: ok, result: res, error: err});
				}
			} catch (e:Dynamic) {}
		});
	}

	public function call(method:String, args:Array<Dynamic>, ?timeoutSec:Float = 15.0):PluginResponse {
		// do we need to drain here?
		while (_responses.pop(false) != null) {}

		var ticket:Int = 0;

		_awaitMux.acquire();
		var locked:Bool = false;
		try {
			if (_awaiting) {
				_awaitMux.release();
				return {
					ok: false,
					error: {code: "BUSY", message: 'Plugin ${name} already has a call in flight.'},
					result: null,
					method: method,
					durationMs: 0,
					ticket: 0
				};
			}
			ticket = ++_ticketCounter;
			_awaiting = true;
			_awaitingTicket = ticket;
			locked = true;
		} catch (_:Dynamic) {
			if (!locked)
				return {
					ok: false,
					error: {code: "HOST_ERROR", message: "Lock failed"},
					result: null,
					method: method,
					durationMs: 0,
					ticket: 0
				};
		}
		if (locked) {
			_awaitMux.release();
		}

		var start:Float = Timer.stamp();

		if (timeoutSec > 0) {
			spawnWatchdog(method, ticket, start, timeoutSec);
		}

		var wire:String = Serializer.run({method: method, args: args});
		try {
			this.stdin.writeInt32(wire.length);
			this.stdin.writeString(wire);
			this.stdin.flush();
		} catch (e:Dynamic) {
			pushEnvelope({
				ok: false,
				error: {code: "IO_ERROR", message: 'Write failed: ' + Std.string(e)},
				result: null
			});
		}
		var env:PluginResponse = _responses.pop(true);

		var elapsedMs:Int = Std.int((Timer.stamp() - start) * 1000);
		env.method = method;
		env.ticket = ticket;
		env.durationMs = elapsedMs;

		_awaitMux.acquire();
		if (_awaiting && _awaitingTicket == ticket) {
			_awaiting = false;
		}
		_awaitMux.release();

		return env;
	}

	public function init(version:String):Bool {
		if (_ready) {
			return true;
		}

		var resp:PluginResponse = this.call("plugin.init", [{hostVersion: version, protocol: 1}], 5.0);
		if (!resp.ok) {
			return false;
		} else {
			Sys.println('[$name] plugin loaded');
		}

		var info:Dynamic = resp.result;
		if (info == null) {
			_ready = true;
			return true;
		}

		if (info.reflection != null) {
			handleReflect(info.reflection);
		}
		pluginVersion = (Reflect.hasField(info, "pluginVersion") ? info.pluginVersion : null);
		capabilities = (Reflect.hasField(info, "capabilities") ? info.capabilities : []);

		_ready = (Reflect.hasField(info, "ok") ? info.ok : true);
		return _ready;
	}

	private function handleReflect(reflection:Dynamic) {
		var reflectFields:Array<String> = Reflect.fields(reflection);
		for (field in reflectFields) {
			var split:Array<String> = field.split("::");
			var className:String = split[0];
			var fieldName:String = split[1];

			var valueSet:Dynamic = Reflect.field(reflection, field);

			var classT:Class<Any> = Type.resolveClass(className);
			var classField:Any = Reflect.field(classT, fieldName);
			var valueT:Class<Any> = Type.getClass(classField);
			var sValueT:String = Std.string(valueT);

			switch (sValueT) {
				case "String":
					handleReflectionString(classT, fieldName, valueSet);
				case "haxe.ds.StringMap":
					handleReflectionStringMap(classT, fieldName, valueSet);
				default:
			}
		}
	}

	private inline function handleReflectionStringMap(classT:Class<Any>, field:String, value:Any) {
        var sMap:StringMap<Dynamic> = Reflect.field(classT, field);            
        
		if (Std.isOfType(value, String)) {
			var split:Array<String> = (value:String).split("=>");
			sMap.set(split[0], split[1]);
		} else if(Std.isOfType(value, Array)) {
            var valueArr:Array<String> = value;
            for(v in valueArr){
                var split:Array<String> = v.split("=>");
                sMap.set(split[0], split[1]);
            }
        }
	}

	private inline function handleReflectionString(classT:Class<Any>, field:String, value:String) {
		if (value.indexOf("::") > -1) {
			var split:Array<String> = value.split("::");
			var className:String = split[0];
			var fieldName:String = split[1];
			value = Reflect.field(Type.resolveClass(className), fieldName);
		}
		Reflect.setField(classT, field, value);
	}

	override public function close():Void {
		_running = false;

		try {
			super.close();
		} catch (e:Dynamic) {}
	}

	private inline function ensureReady():Void {
		if (!_ready) {
			if (!init("0.1.0")) {
				throw 'Plugin ${name} failed init()';
			}
		}
	}

	private inline function pushEnvelope(partial:{ok:Bool, ?result:Dynamic, ?error:PluginError}):Void {
		_responses.push({
			ok: partial.ok,
			result: partial.result,
			error: partial.error,
			method: "",
			durationMs: 0,
			ticket: 0
		});
	}

	private function spawnWatchdog(method:String, ticket:Int, start:Float, timeoutSec:Float):Void {
		Thread.create(() -> {
			var slept = 0.0;
			while (slept < timeoutSec) {
				_awaitMux.acquire();
				var waiting:Bool = _awaiting && (_awaitingTicket == ticket);
				_awaitMux.release();
				if (!waiting) {
					return;
				}

				Sys.sleep(0.01);
				slept += 0.01;
			}
			var ms:Int = Std.int((haxe.Timer.stamp() - start) * 1000);
			_responses.push({
				ok: false,
				result: null,
				error: {code: "TIMEOUT", message: 'Timed out after ${timeoutSec}s calling ' + method},
				method: method,
				durationMs: ms,
				ticket: ticket
			});

			_dropNext = true;
		});
	}

	private static inline function safeReadInt32(inp:Input):Int {
		try {
			return inp.readInt32();
		} catch (e:Dynamic) {
			return -1;
		}
	}

	private static inline function readExact(inp:Input, len:Int):String {
		var b:Bytes = Bytes.alloc(len);
		var off:Int = 0;
		while (off < len) {
			var n:Int = inp.readBytes(b, off, len - off);
			if (n <= 0) {
				throw "Unexpected EOF from plugin";
			}

			off += n;
		}
		return b.toString();
	}
}

typedef PluginError = {
	var code:String;
	var message:String;
	@:optional var data:Dynamic;
}

typedef PluginResponse = {
	var ok:Bool;
	@:optional var result:Dynamic;
	@:optional var error:PluginError;
	var method:String;
	var durationMs:Int;
	var ticket:Int;
}
