package aedifex.build;

import aedifex.build.ProjectSpec.BuildCommand;
import aedifex.build.ProjectSpec.ExtensionCapabilities;
import aedifex.build.ProjectSpec.ExtensionSpec;
import aedifex.build.ProjectSpec.ExtensionSource;
import aedifex.build.ProjectSpec.HaxeFlag;
import aedifex.build.ProjectSpec.LibrarySpec;
import aedifex.build.ProjectSpec.ProjectKind;
import aedifex.build.ProjectSpec.TaskSpec;
import aedifex.build.ProjectSpec.TargetSpec;
import aedifex.build.ProjectSpec.TargetRule;

class Project {
	public static inline final IMPLICIT_TOOL_HAXELIB = "aedifex";

	public static function create():ProjectBuilder {
		return new ProjectBuilder();
	}

	public static function app(mainClassName:String):ProjectBuilder {
		return create().appProject(mainClassName);
	}

	public static function named(mainClassName:String):ProjectBuilder {
		return app(mainClassName);
	}

	public static function library(name:String, ?title:String):ProjectBuilder {
		return create().asLibrary(name, title);
	}

	public static function tool(name:String, ?title:String):ProjectBuilder {
		return create().asTool(name, title);
	}

	public static function plugin(name:String, ?title:String):ProjectBuilder {
		return create().asPlugin(name, title);
	}

	public static function extension(name:String, ?title:String):ProjectBuilder {
		return create().asExtension(name, title);
	}

	public static function fromMain(mainType:Class<Dynamic>):ProjectBuilder {
		return create().main(mainType);
	}
}

class ProjectBuilder {
	private final spec:ProjectSpec;

	public function new() {
		spec = new ProjectSpec();
	}

	public function kind(value:ProjectKind):ProjectBuilder {
		spec.kind = value;
		return this;
	}

	public function appProject(mainClassName:String):ProjectBuilder {
		spec.kind = ProjectKind.APP;
		return mainClass(mainClassName);
	}

	public function asLibrary(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.LIBRARY;
		return projectName(name).title(title != null ? title : name);
	}

	public function asTool(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.TOOL;
		return projectName(name).title(title != null ? title : name);
	}

	public function asPlugin(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.PLUGIN;
		return projectName(name).title(title != null ? title : name);
	}

	public function asExtension(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.EXTENSION;
		return projectName(name).title(title != null ? title : name);
	}

	public function main(mainType:Class<Dynamic>):ProjectBuilder {
		return mainClass(Type.getClassName(mainType));
	}

	public function mainClass(mainClassName:String):ProjectBuilder {
		spec.app.mainClass = mainClassName;
		return this;
	}

	public function projectName(value:String):ProjectBuilder {
		spec.meta.name = value;
		spec.haxelib.name = value;
		return this;
	}

	public function identity(file:String, title:String, ?path:String = "bin"):ProjectBuilder {
		spec.app.file = file;
		spec.meta.name = file;
		spec.haxelib.name = file;
		spec.meta.title = title;
		spec.app.path = path;
		return this;
	}

	public function output(path:String):ProjectBuilder {
		spec.app.path = path;
		return this;
	}

	public function file(value:String):ProjectBuilder {
		spec.app.file = value;
		return this;
	}

	public function title(value:String):ProjectBuilder {
		spec.meta.title = value;
		return this;
	}

	public function version(value:String):ProjectBuilder {
		spec.meta.version = value;
		spec.haxelib.version = value;
		return this;
	}

	public function company(value:String):ProjectBuilder {
		spec.meta.company = value;
		return this;
	}

	public function author(value:String):ProjectBuilder {
		if (value != null && value.length > 0 && spec.meta.authors.indexOf(value) == -1) {
			spec.meta.authors.push(value);
		}
		if (value != null && value.length > 0 && spec.haxelib.contributors.indexOf(value) == -1) {
			spec.haxelib.contributors.push(value);
		}
		return this;
	}

	public function description(value:String):ProjectBuilder {
		spec.meta.description = value;
		spec.haxelib.description = value;
		return this;
	}

	public function url(value:String):ProjectBuilder {
		spec.haxelib.url = value;
		return this;
	}

	public function github(value:String):ProjectBuilder {
		if (value == null || value.length == 0) {
			return this;
		}
		var trimmed = StringTools.trim(value);
		if (StringTools.startsWith(trimmed, "http://") || StringTools.startsWith(trimmed, "https://")) {
			return url(trimmed);
		}
		if (StringTools.startsWith(trimmed, "github.com/")) {
			return url("https://" + trimmed);
		}
		if (StringTools.startsWith(trimmed, "www.github.com/")) {
			return url("https://" + trimmed);
		}
		if (StringTools.startsWith(trimmed, "git@github.com:")) {
			var slug = trimmed.substr("git@github.com:".length);
			if (StringTools.endsWith(slug, ".git")) {
				slug = slug.substr(0, slug.length - 4);
			}
			return url("https://github.com/" + slug);
		}
		if (StringTools.endsWith(trimmed, ".git")) {
			trimmed = trimmed.substr(0, trimmed.length - 4);
		}
		if (StringTools.startsWith(trimmed, "github:")) {
			trimmed = trimmed.substr("github:".length);
		}
		if (StringTools.startsWith(trimmed, "/")) {
			trimmed = trimmed.substr(1);
		}
		if (StringTools.endsWith(trimmed, "/")) {
			trimmed = trimmed.substr(0, trimmed.length - 1);
		}
		if (trimmed.length == 0) {
			return url(value);
		}
		return url("https://github.com/" + trimmed);
	}

	public function license(value:String):ProjectBuilder {
		spec.haxelib.license = value;
		return this;
	}

	public function releaseNote(value:String):ProjectBuilder {
		spec.haxelib.releasenote = value;
		return this;
	}

	public function tag(value:String):ProjectBuilder {
		if (value != null && value.length > 0 && spec.haxelib.tags.indexOf(value) == -1) {
			spec.haxelib.tags.push(value);
		}
		return this;
	}

	public function tags(values:Array<String>):ProjectBuilder {
		for (value in (values != null ? values : [])) {
			tag(value);
		}
		return this;
	}

	public function contributor(value:String):ProjectBuilder {
		if (value != null && value.length > 0 && spec.haxelib.contributors.indexOf(value) == -1) {
			spec.haxelib.contributors.push(value);
		}
		return this;
	}

	public function classPath(value:String):ProjectBuilder {
		if (value != null && value.length > 0) {
			spec.haxelib.classPath = value;
		}
		return this;
	}

	public function defaultTarget(value:BuildTarget):ProjectBuilder {
		spec.defaultTarget = value;
		return this;
	}

	public function defaultPlatform(value:BuildPlatform):ProjectBuilder {
		spec.defaultPlatform = value;
		return this;
	}

	public function defaultArchitecture(value:BuildArchitecture):ProjectBuilder {
		spec.defaultArchitecture = value;
		return this;
	}

	public function defaultProfile(value:Profile):ProjectBuilder {
		spec.defaultProfile = value;
		return this;
	}

	public function source(path:String):ProjectBuilder {
		pushPath(spec.sources, path);
		return this;
	}

	public function sources(paths:Array<String>):ProjectBuilder {
		for (path in (paths != null ? paths : [])) {
			pushPath(spec.sources, path);
		}
		return this;
	}

	public function dependency(library:LibrarySpec):ProjectBuilder {
		if (library != null && isImplicitToolDependency(library.name)) {
			return this;
		}
		if (library != null) spec.libraries.push(library);
		return this;
	}

	public function library(library:LibrarySpec):ProjectBuilder {
		return dependency(library);
	}

	public function haxelib(name:String, ?version:String):ProjectBuilder {
		return library(LibrarySpec.haxelib(name, null, version));
	}

	public function define(value:Define):ProjectBuilder {
		if (value != null) spec.defines.push(value);
		return this;
	}

	public function defineToken(token:String, ?value:String, ?condition:BuildCondition):ProjectBuilder {
		return define(Define.token(token, value, condition));
	}

	public function flag(value:HaxeFlag):ProjectBuilder {
		if (value != null) spec.haxeflags.push(value);
		return this;
	}

	public function haxeflag(name:String, ?value:String, ?condition:BuildCondition):ProjectBuilder {
		return flag(HaxeFlag.named(name, value, condition));
	}

	public function hook(value:BuildCommand):ProjectBuilder {
		if (value != null) spec.hooks.push(value);
		return this;
	}

	public function supportsTarget(
		name:BuildTarget,
		?platform:BuildPlatform,
		?architecture:BuildArchitecture,
		?backend:ResolvedBackend,
		?condition:BuildCondition,
		hidden:Bool = false
	):ProjectBuilder {
		spec.targets.push(TargetSpec.named(name, platform, architecture, backend, condition, hidden));
		return this;
	}

	public function target(
		name:BuildTarget,
		?configure:TargetBuilder->Void,
		?platform:BuildPlatform,
		?architecture:BuildArchitecture,
		?condition:BuildCondition
	):ProjectBuilder {
		supportsTarget(name, platform, architecture, null, condition);
		var activeCondition = BuildCondition.combine(condition, BuildCondition.when(cast name));
		if (platform != null) {
			activeCondition = BuildCondition.combine(activeCondition, BuildCondition.when(cast platform));
		}
		if (architecture != null) {
			activeCondition = BuildCondition.combine(activeCondition, BuildCondition.when(cast architecture));
		}
		return when(activeCondition, configure);
	}

	public function use(extensionClass:Class<IProjectExtension>, ?options:Dynamic):ProjectBuilder {
		if (extensionClass == null) {
			return this;
		}

		var instance:IProjectExtension = Type.createInstance(extensionClass, []);
		var className = Type.getClassName(extensionClass);
		spec.extensions.push(ExtensionSpec.named(className, options, null, ExtensionSource.CLASS, describeExtensionCapabilities(instance)));
		instance.apply(this, options);
		return this;
	}

	public function extend(name:String, ?options:Dynamic, ?condition:BuildCondition):ProjectBuilder {
		spec.extensions.push(ExtensionSpec.named(name, options, condition, ExtensionSource.NAMED));
		return this;
	}

	public function exportsDefineCatalog(catalog:Dynamic):ProjectBuilder {
		var name = resolveTypeName(catalog);
		if (name != null && name.length > 0 && spec.provides.defineCatalogs.indexOf(name) == -1) {
			spec.provides.defineCatalogs.push(name);
		}
		return this;
	}

	public function exportsCommand(name:String):ProjectBuilder {
		if (name != null && name.length > 0 && spec.provides.commands.indexOf(name) == -1) {
			spec.provides.commands.push(name);
		}
		return this;
	}

	public function exportsTarget(name:BuildTarget):ProjectBuilder {
		var value = Std.string(name);
		if (value.length > 0 && spec.provides.targets.indexOf(value) == -1) {
			spec.provides.targets.push(value);
		}
		return this;
	}

	public function exportsProfile(value:Profile):ProjectBuilder {
		var name = Std.string(value);
		if (name.length > 0 && spec.provides.profiles.indexOf(name) == -1) {
			spec.provides.profiles.push(name);
		}
		return this;
	}

	public function exportsExtension(extensionClass:Class<IProjectExtension>, ?options:Dynamic):ProjectBuilder {
		if (extensionClass == null) return this;
		var instance:IProjectExtension = Type.createInstance(extensionClass, []);
		var className = Type.getClassName(extensionClass);
		spec.provides.extensions.push(ExtensionSpec.named(className, options, null, ExtensionSource.CLASS, describeExtensionCapabilities(instance)));
		return this;
	}

	public function exportsNamedExtension(name:String, ?options:Dynamic, ?condition:BuildCondition):ProjectBuilder {
		if (name != null && name.length > 0) {
			spec.provides.extensions.push(ExtensionSpec.named(name, options, condition, ExtensionSource.NAMED));
		}
		return this;
	}

	public function task(
		name:String,
		command:String,
		?args:Array<String>,
		?cwd:String,
		?description:String,
		?condition:BuildCondition
	):ProjectBuilder {
		spec.tasks.push(TaskSpec.named(name, command, args, cwd, description, condition));
		return this;
	}

	public function when(condition:BuildCondition, configure:TargetBuilder->Void):ProjectBuilder {
		var target = new TargetRule();
		target.condition = BuildCondition.clone(condition);
		if (configure != null) configure(new TargetBuilder(target));
		spec.targetRules.push(target);
		return this;
	}

	public function done():ProjectSpec {
		return spec;
	}

	private static function resolveTypeName(value:Dynamic):String {
		if (value == null) return null;
		if (Std.isOfType(value, String)) {
			return cast value;
		}
		return Type.getClassName(cast value);
	}

	private static function pushPath(paths:Array<String>, path:String):Void {
		if (path == null || path.length == 0) return;
		for (existing in paths) {
			if (existing == path) return;
		}
		paths.push(path);
	}

	private static function isImplicitToolDependency(name:String):Bool {
		return name != null && name.toLowerCase() == Project.IMPLICIT_TOOL_HAXELIB;
	}

	private static function describeExtensionCapabilities(instance:IProjectExtension):ExtensionCapabilities {
		if (instance != null && Std.isOfType(instance, IProjectCapabilityProvider)) {
			var provided = cast(instance, IProjectCapabilityProvider).describeCapabilities();
			if (provided != null) {
				var copy = new ExtensionCapabilities();
				copy.description = provided.description;
				copy.defineCatalogs = provided.defineCatalogs != null ? provided.defineCatalogs.copy() : [];
				copy.commands = provided.commands != null ? provided.commands.copy() : [];
				copy.targets = provided.targets != null ? provided.targets.copy() : [];
				copy.profiles = provided.profiles != null ? provided.profiles.copy() : [];
				return copy;
			}
		}

		return new ExtensionCapabilities();
	}
}

class TargetBuilder {
	private final target:TargetRule;

	public function new(target:TargetRule) {
		this.target = target;
	}

	public function source(path:String):TargetBuilder {
		if (path != null && path.length > 0 && target.sources.indexOf(path) == -1) {
			target.sources.push(path);
		}
		return this;
	}

	public function library(value:LibrarySpec):TargetBuilder {
		if (value != null) target.libraries.push(value);
		return this;
	}

	public function haxelib(name:String, ?version:String):TargetBuilder {
		if (name != null && name.length > 0 && name.toLowerCase() == Project.IMPLICIT_TOOL_HAXELIB) {
			return this;
		}
		return library(LibrarySpec.haxelib(name, null, version));
	}

	public function define(value:Define):TargetBuilder {
		if (value != null) target.defines.push(value);
		return this;
	}

	public function defineToken(token:String, ?value:String, ?condition:BuildCondition):TargetBuilder {
		return define(Define.token(token, value, condition));
	}

	public function flag(value:HaxeFlag):TargetBuilder {
		if (value != null) target.haxeflags.push(value);
		return this;
	}

	public function haxeflag(name:String, ?value:String, ?condition:BuildCondition):TargetBuilder {
		return flag(HaxeFlag.named(name, value, condition));
	}

	public function hook(value:BuildCommand):TargetBuilder {
		if (value != null) target.hooks.push(value);
		return this;
	}

	public function extend(name:String, ?options:Dynamic, ?condition:BuildCondition):TargetBuilder {
		target.extensions.push(ExtensionSpec.named(name, options, condition));
		return this;
	}
}
