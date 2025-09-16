package aedifex.config;

typedef DefineKV = {key:String, ?value:String};

typedef AedifexConfig = {
	var config:{
		var meta:{
			title:String,
			version:String,
			company:String,
			author:Array<String>
		};
		var app:{path:String, main:String, file:String};
		var source:{path:String};
		var haxelib:Array<String>;
		var haxedef:Array<Dynamic>;
	};
}
