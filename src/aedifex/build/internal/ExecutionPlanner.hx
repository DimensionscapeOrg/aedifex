package aedifex.build.internal;

import aedifex.build.BuildArchitecture;
import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.build.BuildCondition;
import aedifex.build.Profile;
import aedifex.build.ProjectSpec;
import aedifex.build.ProjectSpec.ProjectKind;
import aedifex.build.ResolvedBackend;
import aedifex.util.SystemUtil;
import haxe.io.Path;

class ExecutionPlanner {
	public static function normalizeTarget(value:String):BuildTarget {
		return BuildTarget.normalize(value);
	}

	public static function normalizePlatform(value:String):BuildPlatform {
		return BuildPlatform.normalize(value);
	}

	public static function normalizeArchitecture(value:String):BuildArchitecture {
		return BuildArchitecture.normalize(value);
	}

	public static function normalizeProfile(value:String, fallback:Profile):Profile {
		if (value == null || StringTools.trim(value).length == 0) {
			return fallback;
		}
		return Profile.normalize(value);
	}

	public static function hostInfo():Dynamic {
		return {
			platform: SystemUtil.hostPlatform(),
			architecture: BuildArchitecture.hostDefault(),
			systemName: Sys.systemName()
		};
	}

	public static function resolveBackend(target:BuildTarget):ResolvedBackend {
		return switch (target) {
			case BuildTarget.CPP: ResolvedBackend.CPP;
			case BuildTarget.HL: ResolvedBackend.HL;
			case BuildTarget.NEKO: ResolvedBackend.NEKO;
			case BuildTarget.JVM: ResolvedBackend.JVM;
			case BuildTarget.PHP: ResolvedBackend.PHP;
			case BuildTarget.JS: ResolvedBackend.JS;
			default: ResolvedBackend.CUSTOM;
		};
	}

	public static function defaultTarget(project:ProjectSpec):BuildTarget {
		if (project != null && project.defaultTarget != null) {
			return project.defaultTarget;
		}

		var declared = firstDeclaredTarget(project);
		if (declared != null) return declared;

		if (project == null || project.kind == null || project.kind == ProjectKind.APP) {
			return BuildTarget.CPP;
		}

		return null;
	}

	public static function defaultPlatform(project:ProjectSpec, target:BuildTarget):BuildPlatform {
		if (project != null && project.defaultPlatform != null) {
			return project.defaultPlatform;
		}

		if (project != null && project.targets != null) {
			for (item in project.targets) {
				if (item == null || item.name != target || item.platform == null) continue;
				if (!BuildCondition.isActive(item.condition, activeProjectTokens())) continue;
				return item.platform;
			}
		}

		return switch (target) {
			case BuildTarget.JS: BuildPlatform.HTML5;
			default: BuildPlatform.hostNative();
		};
	}

	public static function defaultArchitecture(project:ProjectSpec, target:BuildTarget, platform:BuildPlatform):BuildArchitecture {
		if (project != null && project.defaultArchitecture != null) {
			return project.defaultArchitecture;
		}

		if (project != null && project.targets != null) {
			for (item in project.targets) {
				if (item == null || item.name != target) continue;
				if (platform != null && item.platform != null && item.platform != platform) continue;
				if (item.architecture == null) continue;
				if (!BuildCondition.isActive(item.condition, activeProjectTokens())) continue;
				return item.architecture;
			}
		}

		return BuildArchitecture.hostDefault();
	}

	public static function defaultProfile(project:ProjectSpec):Profile {
		if (project != null && project.defaultProfile != null) {
			return project.defaultProfile;
		}
		return Profile.DEBUG;
	}

	public static function allTargetInfos(project:ProjectSpec):Array<Dynamic> {
		var results:Array<Dynamic> = [];
		for (target in BuildTarget.allPublic()) {
			results.push(targetInfo(project, target));
		}
		return results;
	}

	public static function targetInfo(project:ProjectSpec, target:BuildTarget):Dynamic {
		var platform = defaultPlatform(project, target);
		var architecture = defaultArchitecture(project, target, platform);
		var support = evaluateSupport(project, target, platform, architecture);
		return {
			name: Std.string(target),
			backend: Std.string(resolveBackend(target)),
			defaultPlatform: platform != null ? Std.string(platform) : null,
			defaultArchitecture: architecture != null ? Std.string(architecture) : null,
			platforms: [for (value in platformsFor(target)) Std.string(value)],
			declared: support.declared,
			supported: support.buildSupported,
			buildSupported: support.buildSupported,
			runSupported: support.runSupported,
			hostPlatform: hostInfo().platform,
			hostArchitecture: hostInfo().architecture,
			reason: support.reason,
			hidden: support.hidden
		};
	}

	public static function buildPlan(
		projectRoot:String,
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile
	):Dynamic {
		var effectivePlatform = platform != null ? platform : defaultPlatform(project, target);
		var effectiveArchitecture = architecture != null ? architecture : defaultArchitecture(project, target, effectivePlatform);
		var support = evaluateSupport(project, target, effectivePlatform, effectiveArchitecture);
		var resolvedProject = ProjectResolver.resolve(project, target, effectivePlatform, effectiveArchitecture, profile);
		var paths = outputPaths(projectRoot, resolvedProject, target, effectivePlatform, effectiveArchitecture, profile);
		return {
			projectRoot: Path.normalize(projectRoot),
			kind: Std.string(resolvedProject.kind),
			target: Std.string(target),
			platform: effectivePlatform != null ? Std.string(effectivePlatform) : null,
			architecture: effectiveArchitecture != null ? Std.string(effectiveArchitecture) : null,
			backend: Std.string(resolveBackend(target)),
			profile: Std.string(profile),
			supported: support.buildSupported,
			buildSupported: support.buildSupported,
			runSupported: support.runSupported,
			host: hostInfo(),
			constraints: {
				declared: support.declared,
				reason: support.reason
			},
			paths: paths,
			project: resolvedProject,
			provides: resolvedProject.provides,
			launcher: launcherFor(target, effectivePlatform, resolvedProject, paths),
			compiler: {
				command: "haxe",
				backend: Std.string(resolveBackend(target))
			}
		};
	}

	public static function launchPlan(
		projectRoot:String,
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile
	):Dynamic {
		var plan = buildPlan(projectRoot, project, target, platform, architecture, profile);
		return {
			projectRoot: plan.projectRoot,
			kind: plan.kind,
			target: plan.target,
			platform: plan.platform,
			architecture: plan.architecture,
			backend: plan.backend,
			profile: plan.profile,
			supported: plan.runSupported,
			buildSupported: plan.buildSupported,
			runSupported: plan.runSupported,
			host: plan.host,
			constraints: plan.constraints,
			paths: plan.paths,
			provides: plan.provides,
			launcher: plan.launcher
		};
	}

	public static function outputPaths(
		projectRoot:String,
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile
	):Dynamic {
		var outputRoot = project.app != null && project.app.path != null && project.app.path.length > 0 ? project.app.path : "bin";
		var artifactName = project.app != null && project.app.file != null && project.app.file.length > 0 ? project.app.file : defaultArtifactName(project);
		var outDir = Path.join([projectRoot, outputRoot, Std.string(target), Std.string(platform), Std.string(architecture), Std.string(profile)]);
		var binDir = Path.join([outDir, "bin"]);
		var objDir = Path.join([outDir, "obj"]);
		var haxeDir = Path.join([outDir, "haxe"]);
		var artifactPath = switch (resolveBackend(target)) {
			case ResolvedBackend.CPP:
				Path.join([binDir, platform == BuildPlatform.WINDOWS ? artifactName + ".exe" : artifactName]);
			case ResolvedBackend.HL:
				Path.join([binDir, artifactName + ".hl"]);
			case ResolvedBackend.NEKO:
				Path.join([binDir, artifactName + ".n"]);
			case ResolvedBackend.JVM:
				Path.join([binDir, artifactName + ".jar"]);
			case ResolvedBackend.PHP:
				Path.join([binDir, artifactName + ".php"]);
			case ResolvedBackend.JS:
				Path.join([binDir, artifactName + ".js"]);
			default:
				binDir;
		};

		return {
			outDir: outDir,
			binDir: binDir,
			objDir: objDir,
			haxeDir: haxeDir,
			artifactPath: artifactPath
		};
	}

	private static function launcherFor(target:BuildTarget, platform:BuildPlatform, project:ProjectSpec, paths:Dynamic):Dynamic {
		return switch (resolveBackend(target)) {
			case ResolvedBackend.CPP:
				if (SystemUtil.hostPlatform() == "windows") {
					{
						kind: "native",
						debugger: "cppvsdbg",
						command: paths.artifactPath,
						args: [],
						cwd: paths.binDir
					};
				} else {
					{
						kind: "native",
						debugger: "cppdbg",
						command: paths.artifactPath,
						args: [],
						cwd: paths.binDir
					};
				}
			case ResolvedBackend.HL:
				{
					kind: "terminal",
					debugger: null,
					command: "hl",
					args: [paths.artifactPath],
					cwd: paths.binDir
				};
			case ResolvedBackend.NEKO:
				{
					kind: "terminal",
					debugger: null,
					command: "neko",
					args: [paths.artifactPath],
					cwd: paths.binDir
				};
			case ResolvedBackend.JVM:
				{
					kind: "terminal",
					debugger: null,
					command: "java",
					args: ["-jar", paths.artifactPath],
					cwd: paths.binDir
				};
			case ResolvedBackend.PHP:
				{
					kind: "terminal",
					debugger: null,
					command: "php",
					args: [paths.artifactPath],
					cwd: paths.binDir
				};
			case ResolvedBackend.JS:
				if (platform == BuildPlatform.NODE) {
					{
						kind: "terminal",
						debugger: null,
						command: "node",
						args: [paths.artifactPath],
						cwd: paths.binDir
					};
				} else {
					{
						kind: "browser",
						debugger: null,
						command: null,
						args: [],
						cwd: paths.binDir,
						file: paths.artifactPath
					};
				}
			default:
				{
					kind: "terminal",
					debugger: null,
					command: null,
					args: [],
					cwd: paths.binDir
				};
		};
	}

	private static function evaluateSupport(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture
	):{declared:Bool, hidden:Bool, buildSupported:Bool, runSupported:Bool, reason:String} {
		var declaration = targetDeclaration(project, target, platform, architecture);
		if (!declaration.declared) {
			return {
				declared: false,
				hidden: declaration.hidden,
				buildSupported: false,
				runSupported: false,
				reason: declaration.reason
			};
		}

		var hostPlatform = BuildPlatform.hostNative();
		var buildSupported = false;
		var runSupported = false;
		var reason:Null<String> = null;

		switch (target) {
			case BuildTarget.CPP:
				switch (platform) {
					case BuildPlatform.WINDOWS, BuildPlatform.MAC, BuildPlatform.LINUX:
						if (platform != hostPlatform) {
							reason = 'Core Aedifex only builds native `${target}` for the matching host platform.';
						} else {
							buildSupported = true;
							runSupported = true;
						}
					case BuildPlatform.ANDROID:
						reason = "Android was selected, but no Android provider is installed yet.";
					case BuildPlatform.IOS:
						reason = "iOS was selected, but no iOS provider is installed yet.";
					default:
						reason = 'Platform `${platform}` is not valid for target `${target}`.';
				}

			case BuildTarget.HL:
				if (!platform.isNativeHostPlatform()) {
					reason = 'HashLink in core Aedifex currently expects a native host platform.';
				} else if (platform != hostPlatform) {
					reason = 'Core Aedifex only resolves `${target}` for the matching host platform.';
				} else {
					buildSupported = true;
					runSupported = commandExists("hl");
					if (!runSupported) reason = "HashLink is not available on PATH.";
				}

			case BuildTarget.NEKO:
				if (!platform.isNativeHostPlatform()) {
					reason = 'Neko in core Aedifex currently expects a native host platform.';
				} else if (platform != hostPlatform) {
					reason = 'Core Aedifex only resolves `${target}` for the matching host platform.';
				} else {
					buildSupported = true;
					runSupported = commandExists("neko");
					if (!runSupported) reason = "Neko is not available on PATH.";
				}

			case BuildTarget.JVM:
				if (!platform.isNativeHostPlatform()) {
					reason = 'JVM in core Aedifex currently expects a native host platform.';
				} else if (platform != hostPlatform) {
					reason = 'Core Aedifex only resolves `${target}` for the matching host platform.';
				} else {
					buildSupported = true;
					runSupported = commandExists("java");
					if (!runSupported) reason = "Java is not available on PATH.";
				}

			case BuildTarget.PHP:
				if (!platform.isNativeHostPlatform()) {
					reason = 'PHP in core Aedifex currently expects a native host platform.';
				} else if (platform != hostPlatform) {
					reason = 'Core Aedifex only resolves `${target}` for the matching host platform.';
				} else {
					buildSupported = true;
					runSupported = commandExists("php");
					if (!runSupported) reason = "PHP is not available on PATH.";
				}

			case BuildTarget.JS:
				switch (platform) {
					case BuildPlatform.HTML5:
						buildSupported = true;
						runSupported = true;
					case BuildPlatform.NODE:
						buildSupported = true;
						runSupported = commandExists("node");
						if (!runSupported) reason = "Node.js is not available on PATH.";
					default:
						reason = 'Platform `${platform}` is not valid for target `${target}`.';
				}
		}

		if (buildSupported && !hasRunnableEntryPoint(project)) {
			buildSupported = false;
			runSupported = false;
			reason = entryPointReason(project);
		}

		return {
			declared: true,
			hidden: declaration.hidden,
			buildSupported: buildSupported,
			runSupported: runSupported,
			reason: reason
		};
	}

	private static function targetDeclaration(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture
	):{declared:Bool, hidden:Bool, reason:String} {
		var defaults = defaultDeclaredTargets(project);
		var declarations = project != null ? project.targets : null;
		var libraryLike = project != null && project.kind != null && project.kind != ProjectKind.APP;

		if (declarations == null || declarations.length == 0) {
			var declared = defaults.indexOf(target) != -1;
			return {
				declared: declared,
				hidden: false,
				reason: declared
					? null
					: (libraryLike
						? 'This Aedifex ${nonAppRootLabel(project)} root does not declare runnable targets by default. Add `.supportsTarget(...)` if this repo also ships a runnable tool or sample.'
						: "This target is not enabled by the current project or built-in core defaults.")
			};
		}

		for (item in declarations) {
			if (item == null || item.name != target) continue;
			if (item.platform != null && platform != null && item.platform != platform) continue;
			if (item.architecture != null && architecture != null && item.architecture != architecture) continue;
			if (!BuildCondition.isActive(item.condition, activeProjectTokens())) {
				return {
					declared: false,
					hidden: item.hidden,
					reason: "This target is declared, but its condition is not active on the current host."
				};
			}
			return {declared: true, hidden: item.hidden, reason: null};
		}

		return {
			declared: false,
			hidden: false,
			reason: libraryLike
				? 'This target is not declared by the current Aedifex ${nonAppRootLabel(project)} root.'
				: "This target is not declared by the current project."
		};
	}

	private static function nonAppRootLabel(project:ProjectSpec):String {
		if (project == null || project.kind == null) {
			return "non-app";
		}

		return switch (project.kind) {
			case ProjectKind.LIBRARY: "library";
			case ProjectKind.TOOL: "tool";
			case ProjectKind.PLUGIN: "plugin";
			case ProjectKind.EXTENSION: "extension";
			default: "non-app";
		};
	}

	private static function defaultDeclaredTargets(project:ProjectSpec):Array<BuildTarget> {
		if (project != null && project.kind != null && project.kind != ProjectKind.APP) {
			return [];
		}
		return [BuildTarget.CPP, BuildTarget.HL, BuildTarget.NEKO, BuildTarget.JVM, BuildTarget.PHP, BuildTarget.JS];
	}

	private static function firstDeclaredTarget(project:ProjectSpec):BuildTarget {
		if (project == null || project.targets == null) return null;
		for (item in project.targets) {
			if (item == null || item.hidden || item.name == null) continue;
			if (!BuildCondition.isActive(item.condition, activeProjectTokens())) continue;
			return item.name;
		}
		return null;
	}

	private static function activeProjectTokens():Map<String, Bool> {
		var tokens:Map<String, Bool> = new Map();
		tokens.set(SystemUtil.hostPlatform(), true);
		tokens.set(BuildArchitecture.hostDefault(), true);
		return tokens;
	}

	private static function platformsFor(target:BuildTarget):Array<BuildPlatform> {
		return switch (target) {
			case BuildTarget.CPP: [BuildPlatform.ANDROID, BuildPlatform.IOS];
			case BuildTarget.JS: [BuildPlatform.HTML5, BuildPlatform.NODE];
			default: [];
		};
	}

	private static function defaultArtifactName(project:ProjectSpec):String {
		if (project != null && project.app != null && project.app.file != null && project.app.file.length > 0) {
			return project.app.file;
		}
		if (project != null && project.meta != null && project.meta.name != null && project.meta.name.length > 0) {
			return project.meta.name;
		}
		return "Application";
	}

	private static function hasRunnableEntryPoint(project:ProjectSpec):Bool {
		if (project == null) return false;
		if (project.app != null && project.app.mainClass != null && project.app.mainClass.length > 0) {
			return true;
		}
		return project.kind == null || project.kind == ProjectKind.APP;
	}

	private static function entryPointReason(project:ProjectSpec):String {
		var kind = project != null && project.kind != null ? Std.string(project.kind) : "project";
		return 'Aedifex `${kind}` roots do not assume a runnable entry point. Add `.mainClass(...)` if this repo should build or run a target.';
	}

	private static function commandExists(command:String):Bool {
		if (command == null) return false;
		var trimmed = StringTools.trim(command);
		if (trimmed.length == 0) return false;

		var candidates = commandCandidates(trimmed);
		if (trimmed.indexOf("/") != -1 || trimmed.indexOf("\\") != -1 || Path.isAbsolute(trimmed)) {
			for (candidate in candidates) {
				if (isFile(candidate)) return true;
			}
			return false;
		}

		var pathValue = Sys.getEnv("PATH");
		if (pathValue == null || pathValue.length == 0) {
			return false;
		}

		var separator = #if windows ";" #else ":" #end;
		for (directory in pathValue.split(separator)) {
			var normalized = StringTools.trim(directory);
			if (normalized.length == 0) continue;
			for (candidate in candidates) {
				if (isFile(Path.join([normalized, candidate]))) {
					return true;
				}
			}
		}

		return false;
	}

	private static function commandCandidates(command:String):Array<String> {
		var candidates = [command];
		#if windows
		if (Path.extension(command) == null || Path.extension(command).length == 0) {
			var extValue = Sys.getEnv("PATHEXT");
			var extensions = extValue != null && extValue.length > 0 ? extValue.split(";") : [".EXE", ".BAT", ".CMD", ".COM"];
			for (extension in extensions) {
				var normalized = StringTools.trim(extension);
				if (normalized.length == 0) continue;
				var suffix = StringTools.startsWith(normalized, ".") ? normalized : "." + normalized;
				var candidate = command + suffix.toLowerCase();
				if (candidates.indexOf(candidate) == -1) {
					candidates.push(candidate);
				}
				var upper = command + suffix.toUpperCase();
				if (candidates.indexOf(upper) == -1) {
					candidates.push(upper);
				}
			}
		}
		#end
		return candidates;
	}

	private static function isFile(path:String):Bool {
		return sys.FileSystem.exists(path) && !sys.FileSystem.isDirectory(path);
	}
}
