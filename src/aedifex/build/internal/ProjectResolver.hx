package aedifex.build.internal;

import aedifex.build.BuildCondition;
import aedifex.build.BuildArchitecture;
import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.build.Define;
import aedifex.build.Defines;
import aedifex.build.Profile;
import aedifex.build.ProjectSpec;
import aedifex.build.ProjectSpec.AppSpec;
import aedifex.build.ProjectSpec.BuildCommand;
import aedifex.build.ProjectSpec.ExtensionCapabilities;
import aedifex.build.ProjectSpec.ExtensionSpec;
import aedifex.build.ProjectSpec.HaxeFlag;
import aedifex.build.ProjectSpec.HaxelibSpec;
import aedifex.build.ProjectSpec.LibrarySpec;
import aedifex.build.ProjectSpec.MetaSpec;
import aedifex.build.ProjectSpec.ProjectKind;
import aedifex.build.ProjectSpec.ProvidedSpec;
import aedifex.build.ProjectSpec.TaskSpec;
import aedifex.build.ProjectSpec.TargetSpec;
import aedifex.build.ProjectSpec.TargetRule;

class ProjectResolver {
	public static function resolve(
		project:ProjectSpec,
		?target:BuildTarget,
		?platform:BuildPlatform,
		?architecture:BuildArchitecture,
		?profile:Profile
	):ProjectSpec {
		var activeTokens = buildActiveTokens(target, platform, architecture, profile);
		var resolved = new ProjectSpec();
		resolved.kind = project.kind;
		resolved.meta = cloneMeta(project.meta);
		resolved.haxelib = cloneHaxelib(project.haxelib);
		resolved.app = cloneApp(project.app);
		resolved.defaultTarget = project.defaultTarget;
		resolved.defaultPlatform = project.defaultPlatform;
		resolved.defaultArchitecture = project.defaultArchitecture;
		resolved.defaultProfile = project.defaultProfile;
		resolved.targets = cloneTargets(project.targets, activeTokens);
		resolved.sources = normalizePaths(project.sources);
		resolved.libraries = filterLibraries(project.libraries, activeTokens);
		resolved.defines = filterDefines(project.defines, activeTokens);
		resolved.haxeflags = filterFlags(project.haxeflags, activeTokens);
		resolved.hooks = filterHooks(project.hooks, activeTokens);
		resolved.extensions = filterExtensions(project.extensions, activeTokens);
		resolved.provides = cloneProvides(project.provides, activeTokens);
		resolved.tasks = filterTasks(project.tasks, activeTokens);

		for (rule in project.targetRules) {
			if (!BuildCondition.isActive(rule.condition, activeTokens)) continue;
			applyRule(resolved, rule, activeTokens);
		}

		normalizeResolvedProject(resolved);
		return resolved;
	}

	private static function applyRule(resolved:ProjectSpec, rule:TargetRule, activeTokens:Map<String, Bool>):Void {
		for (path in normalizePaths(rule.sources)) {
			if (resolved.sources.indexOf(path) == -1) {
				resolved.sources.push(path);
			}
		}
		for (library in filterLibraries(rule.libraries, activeTokens)) {
			resolved.libraries.push(library);
		}
		for (define in filterDefines(rule.defines, activeTokens)) {
			resolved.defines.push(define);
		}
		for (flag in filterFlags(rule.haxeflags, activeTokens)) {
			resolved.haxeflags.push(flag);
		}
		for (hook in filterHooks(rule.hooks, activeTokens)) {
			resolved.hooks.push(hook);
		}
		for (extension in filterExtensions(rule.extensions, activeTokens)) {
			resolved.extensions.push(extension);
		}
	}

	private static function normalizeResolvedProject(project:ProjectSpec):Void {
		if (project.sources.length == 0) {
			project.sources.push("src");
		}
		if (project.defaultTarget == null) {
			project.defaultTarget = ExecutionPlanner.defaultTarget(project);
		}
		if (project.defaultPlatform == null) {
			project.defaultPlatform = ExecutionPlanner.defaultPlatform(project, project.defaultTarget);
		}
		if (project.defaultArchitecture == null) {
			project.defaultArchitecture = ExecutionPlanner.defaultArchitecture(project, project.defaultTarget, project.defaultPlatform);
		}
		if (project.defaultProfile == null) {
			project.defaultProfile = ExecutionPlanner.defaultProfile(project);
		}
		if (project.app.path == null || project.app.path.length == 0) {
			project.app.path = "bin";
		}

		switch (project.kind) {
			case ProjectKind.APP:
				if (project.app.mainClass == null || project.app.mainClass.length == 0) {
					project.app.mainClass = "Main";
				}
				if (project.app.file == null || project.app.file.length == 0) {
					project.app.file = defaultArtifactFile(project.app.mainClass);
				}
				if (project.meta.name == null || project.meta.name.length == 0) {
					project.meta.name = project.app.file;
				}
				if (project.meta.title == null || project.meta.title.length == 0) {
					project.meta.title = project.app.file;
				}
			default:
				if (project.meta.name == null || project.meta.name.length == 0) {
					project.meta.name = project.meta.title;
				}
				if ((project.app.file == null || project.app.file.length == 0) && project.meta.name != null && project.meta.name.length > 0) {
					project.app.file = project.meta.name;
				}
				if (project.meta.title == null || project.meta.title.length == 0) {
					project.meta.title = project.meta.name != null && project.meta.name.length > 0 ? project.meta.name : "Aedifex Project";
				}
		}

		if (project.meta.version == null || project.meta.version.length == 0) {
			project.meta.version = "1.0.0";
		}
		if (project.haxelib.name == null || project.haxelib.name.length == 0) {
			project.haxelib.name = project.meta.name;
		}
		if (project.haxelib.version == null || project.haxelib.version.length == 0) {
			project.haxelib.version = project.meta.version;
		}
		if (project.haxelib.description == null || project.haxelib.description.length == 0) {
			project.haxelib.description = project.meta.description;
		}
		if ((project.haxelib.contributors == null || project.haxelib.contributors.length == 0) && project.meta.authors != null) {
			project.haxelib.contributors = project.meta.authors.copy();
		}
		if ((project.haxelib.classPath == null || project.haxelib.classPath.length == 0) && project.sources.length > 0) {
			project.haxelib.classPath = project.sources[0];
		}
	}

	private static function defaultArtifactFile(value:String):String {
		if (value == null || value.length == 0) return "Application";
		var parts = value.split(".");
		return parts[parts.length - 1];
	}

	private static function buildActiveTokens(
		?target:BuildTarget,
		?platform:BuildPlatform,
		?architecture:BuildArchitecture,
		?profile:Profile
	):Map<String, Bool> {
		var tokens:Map<String, Bool> = new Map();
		var effectiveProfile = profile != null ? profile : Profile.RELEASE;
		if (target != null) {
			tokens.set(target, true);
			tokens.set(ExecutionPlanner.resolveBackend(target), true);
		}
		if (platform != null) {
			tokens.set(platform, true);
		}
		if (architecture != null) {
			tokens.set(architecture, true);
		}
		switch (effectiveProfile) {
			case Profile.DEBUG:
				tokens.set(Defines.DEBUG, true);
			case Profile.FINAL:
				tokens.set(Defines.FINAL, true);
			default:
				tokens.set(Defines.RELEASE, true);
		}

		tokens.set(ExecutionPlanner.hostInfo().platform, true);

		return tokens;
	}

	private static function normalizePaths(paths:Array<String>):Array<String> {
		var results:Array<String> = [];
		for (path in (paths != null ? paths : [])) {
			if (path == null || path.length == 0 || results.indexOf(path) != -1) continue;
			results.push(path);
		}
		return results;
	}

	private static function filterLibraries(values:Array<LibrarySpec>, activeTokens:Map<String, Bool>):Array<LibrarySpec> {
		var results:Array<LibrarySpec> = [];
		for (value in (values != null ? values : [])) {
			if (value == null || !BuildCondition.isActive(value.condition, activeTokens)) continue;
			var copy = new LibrarySpec();
			copy.name = value.name;
			copy.path = value.path;
			copy.version = value.version;
			copy.condition = BuildCondition.clone(value.condition);
			results.push(copy);
		}
		return results;
	}

	private static function filterDefines(values:Array<Define>, activeTokens:Map<String, Bool>):Array<Define> {
		var results:Array<Define> = [];
		for (value in (values != null ? values : [])) {
			if (value == null || !BuildCondition.isActive(value.condition, activeTokens)) continue;
			results.push(Define.named(value.name, value.value, value.condition));
		}
		return results;
	}

	private static function filterFlags(values:Array<HaxeFlag>, activeTokens:Map<String, Bool>):Array<HaxeFlag> {
		var results:Array<HaxeFlag> = [];
		for (value in (values != null ? values : [])) {
			if (value == null || !BuildCondition.isActive(value.condition, activeTokens)) continue;
			results.push(HaxeFlag.named(value.name, value.value, value.condition));
		}
		return results;
	}

	private static function filterHooks(values:Array<BuildCommand>, activeTokens:Map<String, Bool>):Array<BuildCommand> {
		var results:Array<BuildCommand> = [];
		for (value in (values != null ? values : [])) {
			if (value == null || !BuildCondition.isActive(value.condition, activeTokens)) continue;
			var copy = new BuildCommand();
			copy.command = value.command;
			copy.args = value.args != null ? value.args.copy() : [];
			copy.cwd = value.cwd;
			copy.phase = value.phase;
			copy.condition = BuildCondition.clone(value.condition);
			results.push(copy);
		}
		return results;
	}

	private static function filterExtensions(values:Array<ExtensionSpec>, activeTokens:Map<String, Bool>):Array<ExtensionSpec> {
		var results:Array<ExtensionSpec> = [];
		for (value in (values != null ? values : [])) {
			if (value == null || !BuildCondition.isActive(value.condition, activeTokens)) continue;
			results.push(ExtensionSpec.named(value.name, value.options, value.condition, value.source, cloneCapabilities(value.capabilities)));
		}
		return results;
	}

	private static function filterTasks(values:Array<TaskSpec>, activeTokens:Map<String, Bool>):Array<TaskSpec> {
		var results:Array<TaskSpec> = [];
		for (value in (values != null ? values : [])) {
			if (value == null || !BuildCondition.isActive(value.condition, activeTokens)) continue;
			results.push(TaskSpec.named(value.name, value.command, value.args, value.cwd, value.description, value.condition));
		}
		return results;
	}

	private static function cloneCapabilities(value:ExtensionCapabilities):ExtensionCapabilities {
		var copy = new ExtensionCapabilities();
		if (value == null) return copy;
		copy.description = value.description;
		copy.defineCatalogs = value.defineCatalogs != null ? value.defineCatalogs.copy() : [];
		copy.commands = value.commands != null ? value.commands.copy() : [];
		copy.targets = value.targets != null ? value.targets.copy() : [];
		copy.profiles = value.profiles != null ? value.profiles.copy() : [];
		return copy;
	}

	private static function cloneTargets(values:Array<TargetSpec>, activeTokens:Map<String, Bool>):Array<TargetSpec> {
		var results:Array<TargetSpec> = [];
		for (value in (values != null ? values : [])) {
			if (value == null || !BuildCondition.isActive(value.condition, activeTokens)) continue;
			results.push(TargetSpec.named(value.name, value.platform, value.architecture, value.backend, value.condition, value.hidden));
		}
		return results;
	}

	private static function cloneProvides(value:ProvidedSpec, activeTokens:Map<String, Bool>):ProvidedSpec {
		var provides = new ProvidedSpec();
		if (value == null) return provides;
		provides.defineCatalogs = value.defineCatalogs != null ? value.defineCatalogs.copy() : [];
		provides.commands = value.commands != null ? value.commands.copy() : [];
		provides.targets = value.targets != null ? value.targets.copy() : [];
		provides.profiles = value.profiles != null ? value.profiles.copy() : [];
		provides.extensions = filterExtensions(value.extensions, activeTokens);
		return provides;
	}

	private static function cloneMeta(value:MetaSpec):MetaSpec {
		var meta = new MetaSpec();
		if (value == null) return meta;
		meta.name = value.name;
		meta.title = value.title;
		meta.version = value.version;
		meta.company = value.company;
		meta.authors = value.authors != null ? value.authors.copy() : [];
		meta.description = value.description;
		return meta;
	}

	private static function cloneApp(value:AppSpec):AppSpec {
		var app = new AppSpec();
		if (value == null) return app;
		app.mainClass = value.mainClass;
		app.path = value.path;
		app.file = value.file;
		return app;
	}

	private static function cloneHaxelib(value:HaxelibSpec):HaxelibSpec {
		var spec = new HaxelibSpec();
		if (value == null) return spec;
		spec.name = value.name;
		spec.url = value.url;
		spec.license = value.license;
		spec.tags = value.tags != null ? value.tags.copy() : [];
		spec.description = value.description;
		spec.version = value.version;
		spec.releasenote = value.releasenote;
		spec.contributors = value.contributors != null ? value.contributors.copy() : [];
		spec.classPath = value.classPath;
		return spec;
	}
}
