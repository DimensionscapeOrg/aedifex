package aedifex.core;

enum abstract Target(String) from String to String {
	var Cpp:String = "cpp";
	var HL:String = "hl";
	var Neko:String = "neko";
	var Java:String = "java";
	var JVM:String = "jvm";

	public inline function isCpp():Bool {
		return this == Cpp;
	}
}
