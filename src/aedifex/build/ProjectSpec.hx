package aedifex.build;

@:structInit
class ProjectSpec {
	public var kind:ProjectKind = ProjectKind.APP;
	public var meta:MetaSpec = new MetaSpec();
	public var haxelib:HaxelibSpec = new HaxelibSpec();
	public var app:AppSpec = new AppSpec();
	public var defaultTarget:BuildTarget = null;
	public var defaultPlatform:BuildPlatform = null;
	public var defaultArchitecture:BuildArchitecture = null;
	public var defaultProfile:Profile = Profile.DEBUG;
	public var sources:Array<String> = [];
	public var libraries:Array<LibrarySpec> = [];
	public var defines:Array<Define> = [];
	public var haxeflags:Array<HaxeFlag> = [];
	public var hooks:Array<BuildCommand> = [];
	public var targets:Array<TargetSpec> = [];
	public var targetRules:Array<TargetRule> = [];
	public var extensions:Array<ExtensionSpec> = [];
	public var provides:ProvidedSpec = new ProvidedSpec();
	public var tasks:Array<TaskSpec> = [];

	public function new() {}
}

abstract ProjectKind(String) from String to String {
	public static inline final APP:ProjectKind = "app";
	public static inline final LIBRARY:ProjectKind = "library";
	public static inline final PLUGIN:ProjectKind = "plugin";
	public static inline final TOOL:ProjectKind = "tool";
	public static inline final EXTENSION:ProjectKind = "extension";
}

@:structInit
class MetaSpec {
	public var name:String = null;
	public var title:String = null;
	public var version:String = null;
	public var company:String = null;
	public var authors:Array<String> = [];
	public var description:String = null;

	public function new() {}
}

@:structInit
class HaxelibSpec {
	public var name:String = null;
	public var url:String = null;
	public var license:String = null;
	public var tags:Array<String> = [];
	public var description:String = null;
	public var version:String = null;
	public var releasenote:String = null;
	public var contributors:Array<String> = [];
	public var classPath:String = "src";

	public function new() {}
}

@:structInit
class AppSpec {
	public var mainClass:String = null;
	public var path:String = "bin";
	public var file:String = null;

	public function new() {}
}

@:structInit
class LibrarySpec {
	public var name:String = "";
	public var path:String = null;
	public var version:String = null;
	public var condition:BuildCondition = null;

	public function new() {}

	public static function haxelib(name:String, ?path:String, ?version:String, ?condition:BuildCondition):LibrarySpec {
		var library = new LibrarySpec();
		library.name = name;
		library.path = path;
		library.version = version;
		library.condition = BuildCondition.clone(condition);
		return library;
	}
}

@:structInit
class HaxeFlag {
	public var name:String = "";
	public var value:String = null;
	public var condition:BuildCondition = null;

	public function new() {}

	public static function named(name:String, ?value:String, ?condition:BuildCondition):HaxeFlag {
		var flag = new HaxeFlag();
		flag.name = name;
		flag.value = value;
		flag.condition = BuildCondition.clone(condition);
		return flag;
	}
}

@:structInit
class BuildCommand {
	public var command:String = "";
	public var args:Array<String> = [];
	public var cwd:String = null;
	public var phase:BuildPhase = BuildPhase.PRE_BUILD;
	public var condition:BuildCondition = null;

	public function new() {}

	public static function prebuild(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.PRE_BUILD;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	public static function postbuild(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.POST_BUILD;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	public static function preRun(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.PRE_RUN;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	public static function postRun(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.POST_RUN;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	public static function preFinalize(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.PRE_FINALIZE;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	public static function postFinalize(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.POST_FINALIZE;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}
}

abstract BuildPhase(String) from String to String {
	public static inline final PRE_RESOLVE:BuildPhase = "preResolve";
	public static inline final POST_RESOLVE:BuildPhase = "postResolve";
	public static inline final PRE_BUILD:BuildPhase = "preBuild";
	public static inline final POST_BUILD:BuildPhase = "postBuild";
	public static inline final PRE_RUN:BuildPhase = "preRun";
	public static inline final POST_RUN:BuildPhase = "postRun";
	public static inline final PRE_FINALIZE:BuildPhase = "preFinalize";
	public static inline final POST_FINALIZE:BuildPhase = "postFinalize";
}

@:structInit
class TargetSpec {
	public var name:BuildTarget = null;
	public var platform:BuildPlatform = null;
	public var architecture:BuildArchitecture = null;
	public var backend:ResolvedBackend = null;
	public var condition:BuildCondition = null;
	public var hidden:Bool = false;

	public function new() {}

	public static function named(
		name:BuildTarget,
		?platform:BuildPlatform,
		?architecture:BuildArchitecture,
		?backend:ResolvedBackend,
		?condition:BuildCondition,
		hidden:Bool = false
	):TargetSpec {
		var target = new TargetSpec();
		target.name = name;
		target.platform = platform;
		target.architecture = architecture;
		target.backend = backend;
		target.condition = BuildCondition.clone(condition);
		target.hidden = hidden;
		return target;
	}
}

@:structInit
class ExtensionSpec {
	public var name:String = "";
	public var options:Dynamic = null;
	public var condition:BuildCondition = null;
	public var source:ExtensionSource = ExtensionSource.NAMED;
	public var capabilities:ExtensionCapabilities = new ExtensionCapabilities();

	public function new() {}

	public static function named(
		name:String,
		?options:Dynamic,
		?condition:BuildCondition,
		?source:ExtensionSource,
		?capabilities:ExtensionCapabilities
	):ExtensionSpec {
		var extension = new ExtensionSpec();
		extension.name = name;
		extension.options = options;
		extension.condition = BuildCondition.clone(condition);
		extension.source = source != null ? source : ExtensionSource.NAMED;
		extension.capabilities = capabilities != null ? cloneCapabilities(capabilities) : new ExtensionCapabilities();
		return extension;
	}

	private static function cloneCapabilities(value:ExtensionCapabilities):ExtensionCapabilities {
		if (value == null) return new ExtensionCapabilities();
		var copy = new ExtensionCapabilities();
		copy.description = value.description;
		copy.defineCatalogs = value.defineCatalogs != null ? value.defineCatalogs.copy() : [];
		copy.commands = value.commands != null ? value.commands.copy() : [];
		copy.targets = value.targets != null ? value.targets.copy() : [];
		copy.profiles = value.profiles != null ? value.profiles.copy() : [];
		return copy;
	}
}

@:structInit
class ExtensionCapabilities {
	public var description:String = null;
	public var defineCatalogs:Array<String> = [];
	public var commands:Array<String> = [];
	public var targets:Array<String> = [];
	public var profiles:Array<String> = [];

	public function new() {}

	public static function create(
		?description:String,
		?defineCatalogs:Array<String>,
		?commands:Array<String>,
		?targets:Array<String>,
		?profiles:Array<String>
	):ExtensionCapabilities {
		var value = new ExtensionCapabilities();
		value.description = description;
		value.defineCatalogs = defineCatalogs != null ? defineCatalogs.copy() : [];
		value.commands = commands != null ? commands.copy() : [];
		value.targets = targets != null ? targets.copy() : [];
		value.profiles = profiles != null ? profiles.copy() : [];
		return value;
	}
}

abstract ExtensionSource(String) from String to String {
	public static inline final CLASS:ExtensionSource = "class";
	public static inline final NAMED:ExtensionSource = "named";
}

@:structInit
class ProvidedSpec {
	public var defineCatalogs:Array<String> = [];
	public var commands:Array<String> = [];
	public var targets:Array<String> = [];
	public var profiles:Array<String> = [];
	public var extensions:Array<ExtensionSpec> = [];

	public function new() {}
}

@:structInit
class TaskSpec {
	public var name:String = "";
	public var command:String = "";
	public var args:Array<String> = [];
	public var cwd:String = null;
	public var description:String = null;
	public var condition:BuildCondition = null;

	public function new() {}

	public static function named(
		name:String,
		command:String,
		?args:Array<String>,
		?cwd:String,
		?description:String,
		?condition:BuildCondition
	):TaskSpec {
		var task = new TaskSpec();
		task.name = name;
		task.command = command;
		task.args = args != null ? args.copy() : [];
		task.cwd = cwd;
		task.description = description;
		task.condition = BuildCondition.clone(condition);
		return task;
	}
}

@:structInit
class TargetRule {
	public var condition:BuildCondition = null;
	public var sources:Array<String> = [];
	public var libraries:Array<LibrarySpec> = [];
	public var defines:Array<Define> = [];
	public var haxeflags:Array<HaxeFlag> = [];
	public var hooks:Array<BuildCommand> = [];
	public var extensions:Array<ExtensionSpec> = [];

	public function new() {}
}
