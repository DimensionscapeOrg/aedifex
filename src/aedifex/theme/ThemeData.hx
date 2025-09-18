package aedifex.theme;

typedef RGB = { r:Int, g:Int, b:Int };

typedef Stop = {
	var pos:Float;
	var r:Int;
	var g:Int;
	var b:Int;
};

typedef ThemeData = {
	var name:String;         
	var kind:String;          
	@:optional var head:RGB;  
	@:optional var sub:RGB;
	@:optional var meta:RGB;

	@:optional var sweep:{ s:RGB, e:RGB };
	@:optional var stops:Array<Stop>;   
	@:optional var banner:String;
};