package;

import haxe.Json;
import haxe.Resource;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import util.SystemUtil;
/**
 * ...
 * @author Christopher Speciale
 */
class Aedifex
{

	private static var _args:Array<String>;
	private static var _command:Array<String> = [];
	private static var _config:Dynamic;
	private static var _target:String;
	private static var _targetPath:String;
	private static var _configTemplate:Dynamic;
	private static var _mainTemplate:String;

	static var SPACE:String = " ";
	static var QUOTES:String = '"';
	static var BACKSLASH:String = #if windows "\\" #else "/" #end;
	static var DOT:String = ".";
	static var EXE:String = "exe";
	static var JSON:String = "json";
	static var HAXE:String = "haxe";
	static var CPP:String = "cpp";
	static var HL:String = "hl";
	static var NEKO:String = "neko";
	static var JAVA:String = "java";
	static var JVM:String = "jvm";
	static var DASH:String = "-";
	static var PATH:String = "cp";
	static var MAIN:String = "main";
	static var CONFIG:String = "config";
	static var BIN:String = "bin";
	static var OBJ:String = "obj";
	static var SRC:String = "src";
	static var WINDOWS:String = "windows";
	static var LINUX:String = "linux";
	static var DEFINE:String = "-D";
	

	public static var tempPath(get, null):String;
	public static var target(get, null):String;
	
	static function main()
	{		

		_configTemplate = Json.parse(Resource.getString(CONFIG));
		_mainTemplate = Resource.getString(MAIN);
		
		
		_args = Sys.args();
		
		if (_args.length > 0){
			switch (_args[0].toLowerCase())
			{
				case "build":
					_build();
				case "run":
					_run();
				case "test":
					_test();
				case "create":
					_create();
				default:
					intro();
					_displayInfo();
			}
		} else {
			intro();
			_displayInfo();
		}
		
	}
	
	private static function _displayInfo():Void{
		Sys.println("Use Aedifex help for more commands");
	}

	private static function intro():Void
	{
		#if windows
		Sys.command("echo \u001b[31;1m");
		#else
		Sys.command("echo '\u001b[31;1m'");
		#end

		Sys.print("
 .d8b.  d88888b d8888b. d888888b d88888b d88888b db    db 
d8' `8b 88'     88  `8D   `88'   88'     88'     `8b  d8' 
88ooo88 88ooooo 88   88    88    88ooo   88ooooo  `8bd8'  
88~~~88 88~~~~~ 88   88    88    88~~~   88~~~~~  .dPYb.  
88   88 88.     88  .8D   .88.   88      88.     .8P  Y8. 
YP   YP Y88888P Y8888D' Y888888P YP      Y88888P YP    YP 
");
		#if windows
		Sys.command("echo \u001b[0m");
		#else
		Sys.command("echo '\u001b[0m'");
		#end
		
		Sys.print("All rights reserved. 2020 - 2023(c) Dimensionscape LLC \n");
		
		#if windows
		Sys.command("echo \u001b[37;1m");
		#else
		Sys.command("echo '\u001b[37;1m'");
		#end		
		
		Sys.print("Command-Line Tool (v0.0.1)");
		
		#if windows
		Sys.command('echo \u001b[0m');
		#else
		Sys.command("echo '\u001b[0m'");
		#end
	}

	private static function _push(arg:String, dash:Bool = false):Void
	{
		_command.push((dash ? DASH : "") + arg);
	}

	private static function _test():Void{
		
		if (!_build()){
			return;
		}
		
		if (!_run()){
			return;
		}
		
		 _clearCommand();
		
	}
	
	private static function _create():Bool{
		Sys.println("Creating Project");
				
				if (_args.length >= 2)
				{
					var path:String = _args[1];
					path = Path.removeTrailingSlashes(path);
					_createProjectAt(path);
		
				}
				else {
					Sys.println("Must include source path");
					return false;
				}
		
		_clearCommand();
		Sys.println("New project created");
		return true;
	}
	
	private static function _createProjectAt(path:String):Void{
		
		FileSystem.createDirectory(path);
		FileSystem.createDirectory(path + BACKSLASH + SRC);
		FileSystem.createDirectory(path + BACKSLASH + BIN);
		File.saveContent(path + BACKSLASH + SRC + BACKSLASH + "Main.hx", _mainTemplate);
		
		var normalized = Path.normalize(path);
		var li:Int = normalized.lastIndexOf("/") + 1;	
		var name:String = normalized.substring(li, normalized.length);
		
		_configTemplate.config.meta.title = name;
		_configTemplate.config.app.file = name;
		
		File.saveContent(path + BACKSLASH + CONFIG + DOT + JSON, JsonPrinter.print(_configTemplate, null, "	"));
		
	}
	
	private static function _build():Bool
	{
		Sys.println("Building Project");
		_push(HAXE);
		_push(PATH, true);
		
		if (_args.length < 2){
			Sys.println("Not enough arguments");
			return false;
		}
		
		switch (_args[1].toLowerCase())
		{
			case "cpp":
				_target = CPP;
			case "hl":
				_target = HL;
			case "neko":
				_target = NEKO;
			case "java":
				_target = JAVA;
			case "jvm":
				_target = JVM;
			default:
				Sys.println("Target not recognized");
				return false;
		}
		
		
		
		var path:String = "";

		if (_args.length >= 3)
		{
			path = _args[2];
			path = Path.removeTrailingSlashes(path);
			
			_loadConfig(path);
			
			_targetPath = path + BACKSLASH + _config.config.app.path + BACKSLASH + target;
			
			
			
			if (FileSystem.exists(path))
			{
				_push(Path.normalize(QUOTES + path + BACKSLASH + BIN + BACKSLASH + target + BACKSLASH + HAXE + QUOTES));
			}
			else
			{
				Sys.println("Source path does not exist");
				return false;
			}
			
			_createApplicationEntry();
		}
		else {
			Sys.println("Must include source path");
			return false;
		}
		
		_push(_target, true);

		
		_push(Path.normalize(QUOTES + _targetPath + BACKSLASH + OBJ + QUOTES));		
		
		if (Sys.systemName().toLowerCase() == WINDOWS && _target == CPP){
			_push(DEFINE + SPACE + WINDOWS);
		}
		
		_push(PATH, true);
		_push(Path.normalize(QUOTES + path + BACKSLASH + _config.config.source.path + QUOTES));

		var macroArgument:String = "haxe.macro.Context.getModule('" + _config.config.app.main + "')";
		_push('--macro "$macroArgument"');
		
		
		
		var defines:Array<Dynamic> = _config.config.haxedef;
		
		
		for (define in defines){
			switch(Type.typeof(define)){
				case TClass(String):
					_push('-D $define');
				case TObject:
					if (Reflect.hasField(define, "value") && Reflect.hasField(define, "key")){
					_push('-D ${define.key}=${define.value}');
					}
				default:
			}			
		}
		
		
		if (_args.length >= 4){
			if (_args[3].toLowerCase() == "debug"){
				_push("-D HXCPP_DEBUG");
			}
		}
		
		_push('-D ${SystemUtil.platform}');
		
		_runCommand();
		
		#if windows
		var objBinFile:String = Path.join([_targetPath + BACKSLASH + OBJ, "ProgramMain" + DOT + EXE]);
		#else
		var objBinFile:String = Path.join([_targetPath + BACKSLASH + OBJ, "ProgramMain"]);
		#end
		
		var binDirectory:String = _targetPath + BACKSLASH + BIN;
		#if windows
		var binFile:String = Path.join([binDirectory, _config.config.app.file + DOT + EXE]);
		#else
		var binFile:String = Path.join([binDirectory, _config.config.app.file]);
		#end
		
		if (!FileSystem.exists(binDirectory)){
			FileSystem.createDirectory(binDirectory);
		}
		
		if (!_moveBin(objBinFile, binFile)){
			
			Sys.exit(1);
			return false;
		}		
		
		_clearCommand();
		
		return true;
	}
	
	private static function _createApplicationEntry():Void{
		var tempProgramTemplate:String = Resource.getString("ProgramMain");

		var regex:EReg = new EReg("::.*::","g");
		var programTemplate:String = regex.replace(tempProgramTemplate, _config.config.app.main);
		var haxePath:String = _targetPath + BACKSLASH + HAXE;
		
		if (!FileSystem.exists(haxePath)){
			FileSystem.createDirectory(haxePath);
		}
		var entryPath:String = haxePath + BACKSLASH + "ProgramMain.hx";
		File.saveContent(entryPath, programTemplate);
		
		_push(MAIN, true);
		_push("ProgramMain");
	}
	
	private static function _loadConfig(path:String):Void{
		var path = path + BACKSLASH + CONFIG + DOT + JSON;
		if (!FileSystem.exists(path)){
			Sys.println("No project configuration detected");
			return;
		} else {
			var content:String = File.getContent(path);
			try{
				_config = Json.parse(content);
			} catch (e:Dynamic){
				Sys.println("Failed to parse project configuration file");
				Sys.println(e);
				return;
			}
		}
	}
	private static function _runCommand():Void
	{
		var command:String = _command.join(SPACE);
		
		Sys.println(command);
		
		Sys.command(command);
		
		
		
	}
	
	private static function _moveBin(currentPath:String, newPath:String):Bool{
		if (FileSystem.exists(currentPath)){
			File.copy(currentPath, newPath);
			FileSystem.deleteFile(currentPath);
			return true;
		}
		return false;
	}

	private static function _run():Bool
	{
		Sys.println("Running Project");

		switch (_args[1].toLowerCase())
		{
			case "cpp":
				_target = CPP;
			case "hl":
				_target = HL;
			case "neko":
				_target = NEKO;
			case "java":
				_target = JAVA;
			case "jvm":
				_target = JVM;
			default:
				Sys.println("Target not recognized");
				return false;
		}
		
		var path:String = "";

		if (_args.length >= 3)
		{
			path = _args[2];
			path = Path.removeTrailingSlashes(path);
			
			if (FileSystem.exists(path))
			{
				var binPath:String = path + BACKSLASH + BIN + BACKSLASH + target + BACKSLASH + BIN;
				if (FileSystem.exists(binPath)){
					var files:Array<String> = FileSystem.readDirectory(binPath);
					
					for (file in files){
						if (Path.extension(file) == "exe"){
							_push(Path.normalize(QUOTES + binPath + BACKSLASH + file + QUOTES));
							break;
						}
					}
				} else {
					Sys.println("Bin path does not exist. " + binPath);
					return false;
				}
			}
			else
			{
				Sys.println("Source path does not exist");
				return false;
			}

		}
		else {
			Sys.println("Must include source path");
			return false;
		}
		
		_runCommand();
		//trace("Run Complete");
		_clearCommand();
		
		return true;
	}
	
	private static function _clearCommand():Void{
		_command = [];
	}
	private static function get_target():String{
		
		if (_target == CPP){
			#if windows
			return WINDOWS;
			#else
			return LINUX;
			#end
		}
	
		
		return _target;
	}
	private static function get_tempPath():String
	{
		var path = "";

		//if (System.platformName == "Windows")
		//{
		#if windows
		path = Sys.getEnv("TEMP");
		#else
		path = Sys.getEnv("TMPDIR");
			if (path == null)
			{
				path = "/tmp";
			}
		#end
		trace("PATH", path);
		//}
	/*	else
		{
			path = Sys.getEnv("TMPDIR");

			if (path == null)
			{
				path = "/tmp";
			}
		}*/
		
		return Path.join([path, _config.config.meta.title, "temp", "bin"]);
	}
}