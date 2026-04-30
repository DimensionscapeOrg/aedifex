package aedifex.build;

/** Serializable root project model extracted from `Aedifex.hx`. */
@:structInit
class ProjectSpec {
	/** Root kind such as app, library, tool, plugin, or extension. */
	public var kind:ProjectKind = ProjectKind.APP;
	/** Human-facing metadata used across docs, packaging, and tooling. */
	public var meta:MetaSpec = new MetaSpec();
	/** haxelib-oriented metadata used when syncing or checking `haxelib.json`. */
	public var haxelib:HaxelibSpec = new HaxelibSpec();
	/** App/runtime-specific output information. */
	public var app:AppSpec = new AppSpec();
	/** Default target used when a command does not provide one explicitly. */
	public var defaultTarget:BuildTarget = null;
	/** Default qualifier or platform when one is meaningful for the chosen target. */
	public var defaultPlatform:BuildPlatform = null;
	/** Default architecture. */
	public var defaultArchitecture:BuildArchitecture = null;
	/** Default profile. */
	public var defaultProfile:Profile = Profile.DEBUG;
	/** Source paths included in the project. */
	public var sources:Array<String> = [];
	/** Haxe libraries referenced by the project. */
	public var libraries:Array<LibrarySpec> = [];
	/** Global defines applied to the project. */
	public var defines:Array<Define> = [];
	/** Raw Haxe flags applied to the project. */
	public var haxeflags:Array<HaxeFlag> = [];
	/** Global lifecycle hooks. */
	public var hooks:Array<BuildCommand> = [];
	/** Declared supported targets and target variants. */
	public var targets:Array<TargetSpec> = [];
	/** Conditional target-scoped rules. */
	public var targetRules:Array<TargetRule> = [];
	/** Applied extensions. */
	public var extensions:Array<ExtensionSpec> = [];
	/** Capabilities this root exposes for tooling and downstream consumers. */
	public var provides:ProvidedSpec = new ProvidedSpec();
	/** Named tasks exposed by the project root. */
	public var tasks:Array<TaskSpec> = [];

	public function new() {}
}

/** High-level root categories supported by Aedifex. */
abstract ProjectKind(String) from String to String {
	public static inline final APP:ProjectKind = "app";
	public static inline final LIBRARY:ProjectKind = "library";
	public static inline final PLUGIN:ProjectKind = "plugin";
	public static inline final TOOL:ProjectKind = "tool";
	public static inline final EXTENSION:ProjectKind = "extension";
}

/** Human-facing project metadata. */
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

/** Package metadata used for haxelib sync/export/check flows. */
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

/** Runtime-oriented app metadata such as main class and output location. */
@:structInit
class AppSpec {
	public var mainClass:String = null;
	public var path:String = "bin";
	public var file:String = null;

	public function new() {}
}

/** One Haxe library dependency entry. */
@:structInit
class LibrarySpec {
	public var name:String = "";
	public var path:String = null;
	public var version:String = null;
	public var condition:BuildCondition = null;

	public function new() {}

	/** Creates a haxelib dependency specification. */
	public static function haxelib(name:String, ?path:String, ?version:String, ?condition:BuildCondition):LibrarySpec {
		var library = new LibrarySpec();
		library.name = name;
		library.path = path;
		library.version = version;
		library.condition = BuildCondition.clone(condition);
		return library;
	}
}

/** One raw Haxe compiler flag entry. */
@:structInit
class HaxeFlag {
	public var name:String = "";
	public var value:String = null;
	public var condition:BuildCondition = null;

	public function new() {}

	/** Creates a named Haxe compiler flag, with optional value and condition. */
	public static function named(name:String, ?value:String, ?condition:BuildCondition):HaxeFlag {
		var flag = new HaxeFlag();
		flag.name = name;
		flag.value = value;
		flag.condition = BuildCondition.clone(condition);
		return flag;
	}
}

/** One lifecycle command invoked around build, run, or finalization phases. */
@:structInit
class BuildCommand {
	public var command:String = "";
	public var args:Array<String> = [];
	public var cwd:String = null;
	public var phase:BuildPhase = BuildPhase.PRE_BUILD;
	public var condition:BuildCondition = null;

	public function new() {}

	/** Creates a pre-build hook command. */
	public static function prebuild(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.PRE_BUILD;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	/** Creates a post-build hook command. */
	public static function postbuild(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.POST_BUILD;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	/** Creates a pre-run hook command. */
	public static function preRun(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.PRE_RUN;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	/** Creates a post-run hook command. */
	public static function postRun(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.POST_RUN;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	/** Creates a pre-finalize hook command. */
	public static function preFinalize(command:String, ?args:Array<String>, ?cwd:String, ?condition:BuildCondition):BuildCommand {
		var hook = new BuildCommand();
		hook.command = command;
		hook.args = args != null ? args.copy() : [];
		hook.cwd = cwd;
		hook.phase = BuildPhase.PRE_FINALIZE;
		hook.condition = BuildCondition.clone(condition);
		return hook;
	}

	/** Creates a post-finalize hook command. */
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

/** Lifecycle phases recognized by Aedifex hooks. */
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

/** Declares one supported target variant for a project root. */
@:structInit
class TargetSpec {
	public var name:BuildTarget = null;
	public var platform:BuildPlatform = null;
	public var architecture:BuildArchitecture = null;
	public var backend:ResolvedBackend = null;
	public var condition:BuildCondition = null;
	public var hidden:Bool = false;

	public function new() {}

	/** Creates a supported target declaration. */
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

/** One applied or exported extension reference. */
@:structInit
class ExtensionSpec {
	public var name:String = "";
	public var options:Dynamic = null;
	public var condition:BuildCondition = null;
	public var source:ExtensionSource = ExtensionSource.NAMED;
	public var capabilities:ExtensionCapabilities = new ExtensionCapabilities();

	public function new() {}

	/** Creates a stored extension reference. */
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

/** Capability description exposed by a project extension. */
@:structInit
class ExtensionCapabilities {
	public var description:String = null;
	public var defineCatalogs:Array<String> = [];
	public var commands:Array<String> = [];
	public var targets:Array<String> = [];
	public var profiles:Array<String> = [];

	public function new() {}

	/** Creates a capability description object. */
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

/** Distinguishes class-backed extensions from named external extension references. */
abstract ExtensionSource(String) from String to String {
	public static inline final CLASS:ExtensionSource = "class";
	public static inline final NAMED:ExtensionSource = "named";
}

/** Capabilities this project root advertises to tooling and downstream users. */
@:structInit
class ProvidedSpec {
	public var defineCatalogs:Array<String> = [];
	public var commands:Array<String> = [];
	public var targets:Array<String> = [];
	public var profiles:Array<String> = [];
	public var extensions:Array<ExtensionSpec> = [];

	public function new() {}
}

/** One named task exposed from a project root. */
@:structInit
class TaskSpec {
	public var name:String = "";
	public var command:String = "";
	public var args:Array<String> = [];
	public var cwd:String = null;
	public var description:String = null;
	public var condition:BuildCondition = null;

	public function new() {}

	/** Creates a named task specification. */
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

/** Conditional rule applied to a subset of target/profile/token combinations. */
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
