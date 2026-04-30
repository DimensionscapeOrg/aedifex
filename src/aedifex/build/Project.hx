package aedifex.build;

import aedifex.build.ProjectSpec.AppSpec;
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

/**
 * Entry point for authoring typed `Aedifex.hx` project roots.
 *
 * The static helpers create a `ProjectBuilder`, which is then configured
 * through fluent Haxe calls until `done()` returns a `ProjectSpec`.
 */
class Project {
	public static inline final IMPLICIT_TOOL_HAXELIB = "aedifex";

	/**
	 * Creates an empty project builder.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function create():ProjectBuilder {
		return new ProjectBuilder();
	}

	/**
	 * Creates an app project rooted at the given main class.
	 * @param mainClassName Main class for the app root.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function app(mainClassName:String):ProjectBuilder {
		return create().appProject(mainClassName);
	}

	/**
	 * Alias for `app(...)` used by the common app-root happy path.
	 * @param mainClassName Main class for the app root.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function named(mainClassName:String):ProjectBuilder {
		return app(mainClassName);
	}

	/**
	 * Creates a library root.
	 * @param name Logical library/package name.
	 * @param title Optional human-facing title.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function library(name:String, ?title:String):ProjectBuilder {
		return create().asLibrary(name, title);
	}

	/**
	 * Creates a tool root.
	 * @param name Logical tool/package name.
	 * @param title Optional human-facing title.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function tool(name:String, ?title:String):ProjectBuilder {
		return create().asTool(name, title);
	}

	/**
	 * Creates a plugin root.
	 * @param name Logical plugin/package name.
	 * @param title Optional human-facing title.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function plugin(name:String, ?title:String):ProjectBuilder {
		return create().asPlugin(name, title);
	}

	/**
	 * Creates an extension root.
	 * @param name Logical extension/package name.
	 * @param title Optional human-facing title.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function extension(name:String, ?title:String):ProjectBuilder {
		return create().asExtension(name, title);
	}

	/**
	 * Creates an app builder from a concrete Haxe main type.
	 * @param mainType Main type class reference.
	 * @return A fresh `ProjectBuilder`.
	 */
	public static function fromMain(mainType:Class<Dynamic>):ProjectBuilder {
		return create().main(mainType);
	}
}

/** Fluent builder used inside `Aedifex.hx` to produce a `ProjectSpec`. */
class ProjectBuilder {
	private final spec:ProjectSpec;

	/** Creates a new empty builder backed by a fresh `ProjectSpec`. */
	public function new() {
		spec = new ProjectSpec();
	}

	/**
	 * Sets the root kind explicitly.
	 * @param value Root kind to assign.
	 * @return The same builder for chaining.
	 */
	public function kind(value:ProjectKind):ProjectBuilder {
		spec.kind = value;
		return this;
	}

	/**
	 * Marks the root as an app project and sets the main class.
	 * @param mainClassName Main class for the app root.
	 * @return The same builder for chaining.
	 */
	public function appProject(mainClassName:String):ProjectBuilder {
		spec.kind = ProjectKind.APP;
		return mainClass(mainClassName);
	}

	/**
	 * Marks the root as a library project.
	 * @param name Logical library/package name.
	 * @param title Optional human-facing title.
	 * @return The same builder for chaining.
	 */
	public function asLibrary(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.LIBRARY;
		return projectName(name).title(title != null ? title : name);
	}

	/**
	 * Marks the root as a tool project.
	 * @param name Logical tool/package name.
	 * @param title Optional human-facing title.
	 * @return The same builder for chaining.
	 */
	public function asTool(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.TOOL;
		return projectName(name).title(title != null ? title : name);
	}

	/**
	 * Marks the root as a plugin project.
	 * @param name Logical plugin/package name.
	 * @param title Optional human-facing title.
	 * @return The same builder for chaining.
	 */
	public function asPlugin(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.PLUGIN;
		return projectName(name).title(title != null ? title : name);
	}

	/**
	 * Marks the root as an extension project.
	 * @param name Logical extension/package name.
	 * @param title Optional human-facing title.
	 * @return The same builder for chaining.
	 */
	public function asExtension(name:String, ?title:String):ProjectBuilder {
		spec.kind = ProjectKind.EXTENSION;
		return projectName(name).title(title != null ? title : name);
	}

	/**
	 * Sets the app main class from a concrete Haxe type.
	 * @param mainType Concrete Haxe class reference.
	 * @return The same builder for chaining.
	 */
	public function main(mainType:Class<Dynamic>):ProjectBuilder {
		return mainClass(Type.getClassName(mainType));
	}

	/**
	 * Sets the app main class by name.
	 * @param mainClassName Fully-qualified or root-package main class name.
	 * @return The same builder for chaining.
	 */
	public function mainClass(mainClassName:String):ProjectBuilder {
		spec.app.mainClass = mainClassName;
		return this;
	}

	/**
	 * Sets the logical project/package name.
	 * @param value Package or project name.
	 * @return The same builder for chaining.
	 */
	public function projectName(value:String):ProjectBuilder {
		spec.meta.name = value;
		spec.haxelib.name = value;
		return this;
	}

	/**
	 * Sets the common app identity fields at once:
	 * logical file name, title, and output root.
	 * @param file Logical file/output base name.
	 * @param title Human-facing title.
	 * @param path Output root directory. Defaults to `bin`.
	 * @return The same builder for chaining.
	 */
	public function identity(file:String, title:String, ?path:String = "bin"):ProjectBuilder {
		spec.app.file = file;
		spec.meta.name = file;
		spec.haxelib.name = file;
		spec.meta.title = title;
		spec.app.path = path;
		return this;
	}

	/**
	 * Overrides the app output path root.
	 * @param path Output root directory.
	 * @return The same builder for chaining.
	 */
	public function output(path:String):ProjectBuilder {
		spec.app.path = path;
		return this;
	}

	/**
	 * Overrides the app output file/basename.
	 * @param value Output file or basename.
	 * @return The same builder for chaining.
	 */
	public function file(value:String):ProjectBuilder {
		spec.app.file = value;
		return this;
	}

	/**
	 * Sets the human-facing title.
	 * @param value Human-facing title.
	 * @return The same builder for chaining.
	 */
	public function title(value:String):ProjectBuilder {
		spec.meta.title = value;
		return this;
	}

	/**
	 * Sets the project version and the synced haxelib version.
	 * @param value Version string.
	 * @return The same builder for chaining.
	 */
	public function version(value:String):ProjectBuilder {
		spec.meta.version = value;
		spec.haxelib.version = value;
		return this;
	}

	/**
	 * Sets the company/organization metadata field.
	 * @param value Company or organization name.
	 * @return The same builder for chaining.
	 */
	public function company(value:String):ProjectBuilder {
		spec.meta.company = value;
		return this;
	}

	/**
	 * Adds an author/contributor value if it is not already present.
	 * @param value Contributor name.
	 * @return The same builder for chaining.
	 */
	public function author(value:String):ProjectBuilder {
		if (value != null && value.length > 0 && spec.meta.authors.indexOf(value) == -1) {
			spec.meta.authors.push(value);
		}
		if (value != null && value.length > 0 && spec.haxelib.contributors.indexOf(value) == -1) {
			spec.haxelib.contributors.push(value);
		}
		return this;
	}

	/**
	 * Sets the human-facing description and synced haxelib description.
	 * @param value Description text.
	 * @return The same builder for chaining.
	 */
	public function description(value:String):ProjectBuilder {
		spec.meta.description = value;
		spec.haxelib.description = value;
		return this;
	}

	/**
	 * Sets the package or project URL.
	 * @param value Canonical URL for the project.
	 * @return The same builder for chaining.
	 */
	public function url(value:String):ProjectBuilder {
		spec.haxelib.url = value;
		return this;
	}

	/**
	 * Normalizes a GitHub slug or URL into the canonical project URL.
	 * @param value GitHub slug, SSH URL, or HTTPS URL.
	 * @return The same builder for chaining.
	 */
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

	/**
	 * Sets the package license string.
	 * @param value SPDX-like license string.
	 * @return The same builder for chaining.
	 */
	public function license(value:String):ProjectBuilder {
		spec.haxelib.license = value;
		return this;
	}

	/**
	 * Sets the package release note text.
	 * @param value Release note text.
	 * @return The same builder for chaining.
	 */
	public function releaseNote(value:String):ProjectBuilder {
		spec.haxelib.releasenote = value;
		return this;
	}

	/**
	 * Adds one package tag if it is not already present.
	 * @param value Tag text.
	 * @return The same builder for chaining.
	 */
	public function tag(value:String):ProjectBuilder {
		if (value != null && value.length > 0 && spec.haxelib.tags.indexOf(value) == -1) {
			spec.haxelib.tags.push(value);
		}
		return this;
	}

	/**
	 * Adds multiple package tags.
	 * @param values Tag list.
	 * @return The same builder for chaining.
	 */
	public function tags(values:Array<String>):ProjectBuilder {
		for (value in (values != null ? values : [])) {
			tag(value);
		}
		return this;
	}

	/**
	 * Adds one contributor if it is not already present.
	 * @param value Contributor name.
	 * @return The same builder for chaining.
	 */
	public function contributor(value:String):ProjectBuilder {
		if (value != null && value.length > 0 && spec.haxelib.contributors.indexOf(value) == -1) {
			spec.haxelib.contributors.push(value);
		}
		return this;
	}

	/**
	 * Sets the haxelib class path used for packaging metadata.
	 * @param value Packaging class path, usually `src`.
	 * @return The same builder for chaining.
	 */
	public function classPath(value:String):ProjectBuilder {
		if (value != null && value.length > 0) {
			spec.haxelib.classPath = value;
		}
		return this;
	}

	/**
	 * Sets the default target used when commands omit one.
	 * @param value Default target.
	 * @return The same builder for chaining.
	 */
	public function defaultTarget(value:BuildTarget):ProjectBuilder {
		spec.defaultTarget = value;
		return this;
	}

	/**
	 * Sets the default qualifier or platform when one is meaningful.
	 * @param value Default platform or qualifier.
	 * @return The same builder for chaining.
	 */
	public function defaultPlatform(value:BuildPlatform):ProjectBuilder {
		spec.defaultPlatform = value;
		return this;
	}

	/**
	 * Sets the default architecture.
	 * @param value Default architecture.
	 * @return The same builder for chaining.
	 */
	public function defaultArchitecture(value:BuildArchitecture):ProjectBuilder {
		spec.defaultArchitecture = value;
		return this;
	}

	/**
	 * Sets the default build profile.
	 * @param value Default profile.
	 * @return The same builder for chaining.
	 */
	public function defaultProfile(value:Profile):ProjectBuilder {
		spec.defaultProfile = value;
		return this;
	}

	/**
	 * Adds one source path to the project.
	 * @param path Source path.
	 * @return The same builder for chaining.
	 */
	public function source(path:String):ProjectBuilder {
		pushPath(spec.sources, path);
		return this;
	}

	/**
	 * Adds multiple source paths to the project.
	 * @param paths Source path list.
	 * @return The same builder for chaining.
	 */
	public function sources(paths:Array<String>):ProjectBuilder {
		for (path in (paths != null ? paths : [])) {
			pushPath(spec.sources, path);
		}
		return this;
	}

	/**
	 * Adds a library dependency entry.
	 * @param library Library specification.
	 * @return The same builder for chaining.
	 */
	public function dependency(library:LibrarySpec):ProjectBuilder {
		if (library != null && isImplicitToolDependency(library.name)) {
			return this;
		}
		if (library != null) spec.libraries.push(library);
		return this;
	}

	/**
	 * Alias for `dependency(...)`.
	 * @param library Library specification.
	 * @return The same builder for chaining.
	 */
	public function library(library:LibrarySpec):ProjectBuilder {
		return dependency(library);
	}

	/**
	 * Adds a normal haxelib dependency by name and optional version.
	 * @param name Haxelib package name.
	 * @param version Optional version constraint.
	 * @return The same builder for chaining.
	 */
	public function haxelib(name:String, ?version:String):ProjectBuilder {
		return library(LibrarySpec.haxelib(name, null, version));
	}

	/**
	 * Adds one define entry.
	 * @param value Define specification.
	 * @return The same builder for chaining.
	 */
	public function define(value:Define):ProjectBuilder {
		if (value != null) spec.defines.push(value);
		return this;
	}

	/**
	 * Adds one define from a token plus optional value and condition.
	 * @param token Define token or custom define name.
	 * @param value Optional define value.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
	public function defineToken(token:String, ?value:String, ?condition:BuildCondition):ProjectBuilder {
		return define(Define.token(token, value, condition));
	}

	/**
	 * Adds one raw Haxe compiler flag.
	 * @param value Haxe flag specification.
	 * @return The same builder for chaining.
	 */
	public function flag(value:HaxeFlag):ProjectBuilder {
		if (value != null) spec.haxeflags.push(value);
		return this;
	}

	/**
	 * Adds one named Haxe compiler flag.
	 * @param name Haxe flag name without leading `-`.
	 * @param value Optional flag value.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
	public function haxeflag(name:String, ?value:String, ?condition:BuildCondition):ProjectBuilder {
		return flag(HaxeFlag.named(name, value, condition));
	}

	/**
	 * Adds one lifecycle hook command.
	 * @param value Hook specification.
	 * @return The same builder for chaining.
	 */
	public function hook(value:BuildCommand):ProjectBuilder {
		if (value != null) spec.hooks.push(value);
		return this;
	}

	/**
	 * Declares that the project supports a target, optionally narrowed by qualifier or architecture.
	 * @param name Target to advertise.
	 * @param platform Optional qualifier or platform restriction.
	 * @param architecture Optional architecture restriction.
	 * @param backend Optional forced backend.
	 * @param condition Optional activation condition.
	 * @param hidden Whether tooling should hide this target variant from the public surface.
	 * @return The same builder for chaining.
	 */
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

	/**
	 * Declares a target and immediately opens a conditional target rule builder
	 * scoped to the same target tokens.
	 * @param name Target to declare.
	 * @param configure Callback for target-scoped modifications.
	 * @param platform Optional qualifier or platform restriction.
	 * @param architecture Optional architecture restriction.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
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

	/**
	 * Applies a class-backed project extension immediately and records it in the project model.
	 * @param extensionClass Extension class to instantiate.
	 * @param options Optional extension-specific configuration object.
	 * @return The same builder for chaining.
	 */
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

	/**
	 * Records a named extension reference without instantiating local Haxe code.
	 * @param name External extension name.
	 * @param options Optional configuration object.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
	public function extend(name:String, ?options:Dynamic, ?condition:BuildCondition):ProjectBuilder {
		spec.extensions.push(ExtensionSpec.named(name, options, condition, ExtensionSource.NAMED));
		return this;
	}

	/**
	 * Advertises an exported define catalog to tooling.
	 * @param catalog Define catalog type or name.
	 * @return The same builder for chaining.
	 */
	public function exportsDefineCatalog(catalog:Dynamic):ProjectBuilder {
		var name = resolveTypeName(catalog);
		if (name != null && name.length > 0 && spec.provides.defineCatalogs.indexOf(name) == -1) {
			spec.provides.defineCatalogs.push(name);
		}
		return this;
	}

	/**
	 * Advertises an exported command to tooling.
	 * @param name Command name.
	 * @return The same builder for chaining.
	 */
	public function exportsCommand(name:String):ProjectBuilder {
		if (name != null && name.length > 0 && spec.provides.commands.indexOf(name) == -1) {
			spec.provides.commands.push(name);
		}
		return this;
	}

	/**
	 * Advertises an exported target to tooling.
	 * @param name Target token.
	 * @return The same builder for chaining.
	 */
	public function exportsTarget(name:BuildTarget):ProjectBuilder {
		var value = Std.string(name);
		if (value.length > 0 && spec.provides.targets.indexOf(value) == -1) {
			spec.provides.targets.push(value);
		}
		return this;
	}

	/**
	 * Advertises an exported profile to tooling.
	 * @param value Profile token.
	 * @return The same builder for chaining.
	 */
	public function exportsProfile(value:Profile):ProjectBuilder {
		var name = Std.string(value);
		if (name.length > 0 && spec.provides.profiles.indexOf(name) == -1) {
			spec.provides.profiles.push(name);
		}
		return this;
	}

	/**
	 * Advertises a class-backed exported extension to tooling.
	 * @param extensionClass Extension class to expose.
	 * @param options Optional configuration object.
	 * @return The same builder for chaining.
	 */
	public function exportsExtension(extensionClass:Class<IProjectExtension>, ?options:Dynamic):ProjectBuilder {
		if (extensionClass == null) return this;
		var instance:IProjectExtension = Type.createInstance(extensionClass, []);
		var className = Type.getClassName(extensionClass);
		spec.provides.extensions.push(ExtensionSpec.named(className, options, null, ExtensionSource.CLASS, describeExtensionCapabilities(instance)));
		return this;
	}

	/**
	 * Advertises a named exported extension to tooling.
	 * @param name Extension name.
	 * @param options Optional configuration object.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
	public function exportsNamedExtension(name:String, ?options:Dynamic, ?condition:BuildCondition):ProjectBuilder {
		if (name != null && name.length > 0) {
			spec.provides.extensions.push(ExtensionSpec.named(name, options, condition, ExtensionSource.NAMED));
		}
		return this;
	}

	/**
	 * Adds a named task to the root.
	 * @param name Task name.
	 * @param command Executable or command name.
	 * @param args Optional argument list.
	 * @param cwd Optional working directory.
	 * @param description Optional human-facing description.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
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

	/**
	 * Adds a conditional target rule configured through a `TargetBuilder`.
	 * @param condition Activation condition.
	 * @param configure Callback receiving the target rule builder.
	 * @return The same builder for chaining.
	 */
	public function when(condition:BuildCondition, configure:TargetBuilder->Void):ProjectBuilder {
		var target = new TargetRule();
		target.condition = BuildCondition.clone(condition);
		if (configure != null) configure(new TargetBuilder(target));
		spec.targetRules.push(target);
		return this;
	}

	/**
	 * Finishes the fluent builder and returns the extracted project model.
	 * @return The completed `ProjectSpec`.
	 */
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

/** Conditional builder used inside `Project.target(...)` and `Project.when(...)`. */
class TargetBuilder {
	private final target:TargetRule;

	/**
	 * Creates a builder around one `TargetRule`.
	 * @param target Mutable target rule being configured.
	 */
	public function new(target:TargetRule) {
		this.target = target;
	}

	/**
	 * Adds a source path only when the enclosing target rule is active.
	 * @param path Source path.
	 * @return The same builder for chaining.
	 */
	public function source(path:String):TargetBuilder {
		if (path != null && path.length > 0 && target.sources.indexOf(path) == -1) {
			target.sources.push(path);
		}
		return this;
	}

	/**
	 * Adds a library only when the enclosing target rule is active.
	 * @param value Library specification.
	 * @return The same builder for chaining.
	 */
	public function library(value:LibrarySpec):TargetBuilder {
		if (value != null) target.libraries.push(value);
		return this;
	}

	/**
	 * Adds a haxelib dependency only when the enclosing target rule is active.
	 * @param name Haxelib package name.
	 * @param version Optional version constraint.
	 * @return The same builder for chaining.
	 */
	public function haxelib(name:String, ?version:String):TargetBuilder {
		if (name != null && name.length > 0 && name.toLowerCase() == Project.IMPLICIT_TOOL_HAXELIB) {
			return this;
		}
		return library(LibrarySpec.haxelib(name, null, version));
	}

	/**
	 * Adds a define only when the enclosing target rule is active.
	 * @param value Define specification.
	 * @return The same builder for chaining.
	 */
	public function define(value:Define):TargetBuilder {
		if (value != null) target.defines.push(value);
		return this;
	}

	/**
	 * Adds a define token only when the enclosing target rule is active.
	 * @param token Define token or custom define name.
	 * @param value Optional define value.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
	public function defineToken(token:String, ?value:String, ?condition:BuildCondition):TargetBuilder {
		return define(Define.token(token, value, condition));
	}

	/**
	 * Adds a raw Haxe compiler flag only when the enclosing target rule is active.
	 * @param value Haxe flag specification.
	 * @return The same builder for chaining.
	 */
	public function flag(value:HaxeFlag):TargetBuilder {
		if (value != null) target.haxeflags.push(value);
		return this;
	}

	/**
	 * Adds a named Haxe compiler flag only when the enclosing target rule is active.
	 * @param name Haxe flag name without leading `-`.
	 * @param value Optional flag value.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
	public function haxeflag(name:String, ?value:String, ?condition:BuildCondition):TargetBuilder {
		return flag(HaxeFlag.named(name, value, condition));
	}

	/**
	 * Adds a lifecycle hook only when the enclosing target rule is active.
	 * @param value Hook specification.
	 * @return The same builder for chaining.
	 */
	public function hook(value:BuildCommand):TargetBuilder {
		if (value != null) target.hooks.push(value);
		return this;
	}

	/**
	 * Adds a named extension reference only when the enclosing target rule is active.
	 * @param name Extension name.
	 * @param options Optional configuration object.
	 * @param condition Optional activation condition.
	 * @return The same builder for chaining.
	 */
	public function extend(name:String, ?options:Dynamic, ?condition:BuildCondition):TargetBuilder {
		target.extensions.push(ExtensionSpec.named(name, options, condition));
		return this;
	}
}
