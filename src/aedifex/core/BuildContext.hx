package aedifex.core;

import aedifex.build.ProjectSpec;
import aedifex.config.AedifexConfig;

@:forward
abstract BuildContext(Dynamic) from Dynamic to Dynamic {
	public var projectRoot(get, set):String;
	public var target(get, set):String;
	public var backend(get, set):String;
	public var host(get, set):String;
	public var profile(get, set):String;
	public var outDir(get, set):String;
	public var binDir(get, set):String;
	public var objDir(get, set):String;
	public var haxeDir(get, set):String;
	public var srcDir(get, set):String;

	@:optional public var defines(get, set):Array<String>;
	@:optional public var libs(get, set):Array<String>;
	@:optional public var platform(get, set):String;
	@:optional public var architecture(get, set):String;
	@:optional public var env(get, set):String;
	@:optional public var config(get, set):AedifexConfig;
	@:optional public var project(get, set):ProjectSpec;
	@:optional public var changed(get, set):Array<String>;

	private inline function get_projectRoot():String {
		return this.projectRoot;
	}

	private inline function set_projectRoot(value:String):String {
		return this.projectRoot = value;
	}

	private inline function get_target():String {
		return this.target;
	}

	private inline function set_target(value:String):String {
		return this.target = value;
	}

	private inline function get_backend():String {
		return this.backend;
	}

	private inline function set_backend(value:String):String {
		return this.backend = value;
	}

	private inline function get_host():String {
		return this.host;
	}

	private inline function set_host(value:String):String {
		return this.host = value;
	}

	private inline function get_profile():String {
		return this.profile;
	}

	private inline function set_profile(value:String):String {
		return this.profile = value;
	}

	private inline function get_outDir():String {
		return this.outDir;
	}

	private inline function set_outDir(value:String):String {
		return this.outDir = value;
	}

	private inline function get_binDir():String {
		return this.binDir;
	}

	private inline function set_binDir(value:String):String {
		return this.binDir = value;
	}

	private inline function get_objDir():String {
		return this.objDir;
	}

	private inline function set_objDir(value:String):String {
		return this.objDir = value;
	}

	private inline function get_haxeDir():String {
		return this.haxeDir;
	}

	private inline function set_haxeDir(value:String):String {
		return this.haxeDir = value;
	}

	private inline function get_srcDir():String {
		return this.srcDir;
	}

	private inline function set_srcDir(value:String):String {
		return this.srcDir = value;
	}

	private inline function get_defines():Array<String> {
		return this.defines;
	}

	private inline function set_defines(value:Array<String>):Array<String> {
		return this.defines = value;
	}

	private inline function get_libs():Array<String> {
		return this.libs;
	}

	private inline function set_libs(value:Array<String>):Array<String> {
		return this.libs = value;
	}

	private inline function get_platform():String {
		return this.platform;
	}

	private inline function set_platform(value:String):String {
		return this.platform = value;
	}

	private inline function get_architecture():String {
		return this.architecture;
	}

	private inline function set_architecture(value:String):String {
		return this.architecture = value;
	}

	private inline function get_env():String {
		return this.env;
	}

	private inline function set_env(value:String):String {
		return this.env = value;
	}

	private inline function get_config():AedifexConfig {
		return this.config;
	}

	private inline function set_config(value:AedifexConfig):AedifexConfig {
		return this.config = value;
	}

	private inline function get_project():ProjectSpec {
		return this.project;
	}

	private inline function set_project(value:ProjectSpec):ProjectSpec {
		return this.project = value;
	}

	private inline function get_changed():Array<String> {
		return this.changed;
	}

	private inline function set_changed(value:Array<String>):Array<String> {
		return this.changed = value;
	}

	public function new() {
		this = {};
	}
}
