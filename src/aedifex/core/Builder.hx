package aedifex.core;

import aedifex.build.BuildArchitecture;
import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.build.Profile;
import aedifex.build.ProjectSpec;
import aedifex.build.ProjectSpec.BuildCommand;
import aedifex.build.ProjectSpec.BuildPhase;
import aedifex.build.ResolvedBackend;
import aedifex.build.internal.ExecutionPlanner;
import aedifex.build.internal.ProjectResolver;
import aedifex.config.Loader;
import aedifex.util.SystemUtil;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class Builder {
	public static function build(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectRoot:String,
		extraDefs:Array<String>,
		extraLibs:Array<String>
	):BuildContext {
		var buildPlan = ExecutionPlanner.buildPlan(projectRoot, project, target, platform, architecture, profile);
		if (!buildPlan.buildSupported) {
			throw buildPlan.constraints.reason != null ? buildPlan.constraints.reason : 'Target `${target}` is not buildable on this host.';
		}

		var resolved:ProjectSpec = cast buildPlan.project;
		var backend:ResolvedBackend = cast buildPlan.backend;
		var paths:Dynamic = buildPlan.paths;
		var effectivePlatform:BuildPlatform = cast buildPlan.platform;
		var effectiveArchitecture:BuildArchitecture = cast buildPlan.architecture;
		var srcDirs:Array<String> = [for (source in resolved.sources) Path.join([projectRoot, source])];
		var primarySrc:String = srcDirs.length > 0 ? srcDirs[0] : Path.join([projectRoot, "src"]);

		if (resolved.app.mainClass == null || resolved.app.mainClass.length == 0) {
			throw 'Aedifex `${resolved.kind}` roots do not assume a runnable entry point. Add `.mainClass(...)` if this repo should build a target.';
		}

		ensureDir(paths.objDir);
		ensureDir(paths.haxeDir);

		var buildContext = new BuildContext();
		buildContext.projectRoot = projectRoot;
		buildContext.target = Std.string(target);
		buildContext.backend = Std.string(backend);
		buildContext.host = SystemUtil.hostPlatform();
		buildContext.platform = Std.string(effectivePlatform);
		buildContext.architecture = Std.string(effectiveArchitecture);
		buildContext.env = Std.string(effectivePlatform);
		buildContext.profile = Std.string(profile);
		buildContext.outDir = paths.outDir;
		buildContext.binDir = paths.binDir;
		buildContext.objDir = paths.objDir;
		buildContext.haxeDir = paths.haxeDir;
		buildContext.srcDir = primarySrc;
		buildContext.defines = flattenDefines(resolved).concat(extraDefs);
		buildContext.libs = flattenLibraries(resolved).concat(extraLibs);
		buildContext.config = Loader.toLegacy(resolved);
		buildContext.project = resolved;

		ProgramWriter.ensure(paths.haxeDir, resolved.app.mainClass);

		runHooks(resolved.hooks, BuildPhase.PRE_BUILD, projectRoot);

		var cmd = new Command();
		cmd.add("haxe");
		for (src in srcDirs) {
			cmd.add("-cp");
			cmd.add(src);
		}
		cmd.add("-cp");
		cmd.add(paths.haxeDir);
		cmd.add("-main");
		cmd.add("ProgramMain");

		for (lib in resolved.libraries) {
			if (lib.path != null && lib.path.length > 0) {
				cmd.add("-cp");
				cmd.add(Path.isAbsolute(lib.path) ? lib.path : Path.join([projectRoot, lib.path]));
			}
			if (lib.name != null && lib.name.length > 0) {
				cmd.add("-lib");
				cmd.add(lib.name);
			}
		}

		for (lib in extraLibs) {
			cmd.add("-lib");
			cmd.add(lib);
		}

		for (d in resolved.defines) {
			cmd.add("-D");
			cmd.add(d.value == null ? d.name : d.name + "=" + d.value);
		}

		for (d in extraDefs) {
			cmd.add("-D");
			cmd.add(d);
		}

		cmd.add("-D");
		cmd.add(SystemUtil.platform);
		cmd.add("-D");
		cmd.add("aedifex_target=" + target);
		cmd.add("-D");
		cmd.add("aedifex_platform=" + effectivePlatform);
		cmd.add("-D");
		cmd.add("aedifex_arch=" + effectiveArchitecture);

		switch (profile) {
			case Profile.DEBUG:
				cmd.add("-D");
				cmd.add("debug");
				cmd.add("-D");
				cmd.add("HXCPP_DEBUGGER");
			case Profile.FINAL:
				cmd.add("-D");
				cmd.add("final");
			default:
		}

		switch (backend) {
			case ResolvedBackend.CPP:
				cmd.add("-cpp");
				cmd.add(paths.objDir);
			case ResolvedBackend.HL:
				ensureDir(Path.directory(paths.artifactPath));
				cmd.add("-hl");
				cmd.add(paths.artifactPath);
			case ResolvedBackend.NEKO:
				ensureDir(Path.directory(paths.artifactPath));
				cmd.add("-neko");
				cmd.add(paths.artifactPath);
			case ResolvedBackend.JVM:
				ensureDir(Path.directory(paths.artifactPath));
				cmd.add("--jvm");
				cmd.add(paths.artifactPath);
			case ResolvedBackend.PHP:
				ensureDir(paths.binDir);
				cmd.add("-php");
				cmd.add(paths.binDir);
			case ResolvedBackend.JS:
				ensureDir(Path.directory(paths.artifactPath));
				cmd.add("-js");
				cmd.add(paths.artifactPath);
			case ResolvedBackend.HTML5, ResolvedBackend.CUSTOM:
				throw 'No built-in builder is available for backend `${backend}`.';
		}

		for (flag in resolved.haxeflags) {
			cmd.add(flag.name);
			if (flag.value != null) {
				cmd.add(flag.value);
			}
		}

		cmd.add("--macro");
		cmd.add("haxe.macro.Context.getModule('" + resolved.app.mainClass + "')");

		var code = cmd.run();
		if (code != 0) {
			throw "haxe failed with exit " + code;
		}

		switch (backend) {
			case ResolvedBackend.CPP:
				finalizeCppBinary(paths.outDir, resolved.app.file, effectivePlatform);
			case ResolvedBackend.PHP:
				finalizePHP(paths.binDir, resolved.app.file);
			default:
		}

		runHooks(resolved.hooks, BuildPhase.POST_BUILD, projectRoot);
		return buildContext;
	}

	public static function rebuild(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectRoot:String,
		extraDefs:Array<String>,
		extraLibs:Array<String>
	):BuildContext {
		var buildPlan = ExecutionPlanner.buildPlan(projectRoot, project, target, platform, architecture, profile);
		if (!buildPlan.buildSupported) {
			throw buildPlan.constraints.reason != null ? buildPlan.constraints.reason : 'Target `${target}` is not buildable on this host.';
		}

		var paths:Dynamic = buildPlan.paths;
		if (FileSystem.exists(paths.outDir)) {
			deleteRecursive(paths.outDir);
		}

		return build(project, target, platform, architecture, profile, projectRoot, extraDefs, extraLibs);
	}

	public static function clean(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectRoot:String
	):String {
		var buildPlan = ExecutionPlanner.buildPlan(projectRoot, project, target, platform, architecture, profile);
		var paths:Dynamic = buildPlan.paths;
		if (FileSystem.exists(paths.outDir)) {
			deleteRecursive(paths.outDir);
		}
		return paths.outDir;
	}

	public static function runHooks(hooks:Array<BuildCommand>, phase:BuildPhase, projectRoot:String):Void {
		for (hook in (hooks != null ? hooks : [])) {
			if (hook == null || hook.phase != phase) continue;

			var cmd = new Command();
			cmd.add(hook.command);
			cmd.addMany(hook.args != null ? hook.args : []);
			var previous = Sys.getCwd();
			var failure:Dynamic = null;
			try {
				Sys.setCwd(hook.cwd != null ? Path.join([projectRoot, hook.cwd]) : projectRoot);
				var code = cmd.run();
				if (code != 0) {
					failure = 'Hook failed (`${hook.command}`) with exit ' + code;
				}
			} catch (e:Dynamic) {
				failure = e;
			}
			Sys.setCwd(previous);
			if (failure != null) {
				throw failure;
			}
		}
	}

	private static inline function ensureDir(path:String):Void {
		if (path == null || path.length == 0 || FileSystem.exists(path)) {
			return;
		}
		var parent = Path.directory(path);
		if (parent != null && parent.length > 0 && parent != path && !FileSystem.exists(parent)) {
			ensureDir(parent);
		}
		FileSystem.createDirectory(path);
	}

	private static function flattenDefines(project:ProjectSpec):Array<String> {
		var flattened:Array<String> = [];
		for (d in project.defines) {
			if (d == null) continue;
			flattened.push(d.value == null ? d.name : d.name + "=" + d.value);
		}
		return flattened;
	}

	private static function flattenLibraries(project:ProjectSpec):Array<String> {
		var flattened:Array<String> = [];
		for (library in project.libraries) {
			if (library == null) continue;
			if (library.name != null && library.name.length > 0) {
				flattened.push(library.name);
			} else if (library.path != null && library.path.length > 0) {
				flattened.push(library.path);
			}
		}
		return flattened;
	}

	private static function finalizeCppBinary(outRoot:String, appFile:String, platform:BuildPlatform):Void {
		var executableName = platform == BuildPlatform.WINDOWS ? "ProgramMain.exe" : "ProgramMain";
		var obj = findFileRecursive(Path.join([outRoot, "obj"]), executableName);
		var dstDir = Path.join([outRoot, "bin"]);
		ensureDir(dstDir);
		var dst = Path.join([dstDir, platform == BuildPlatform.WINDOWS ? appFile + ".exe" : appFile]);
		if (obj == null || !FileSystem.exists(obj)) {
			throw 'Expected obj binary missing under ' + Path.join([outRoot, "obj"]);
		}
		try {
			File.copy(obj, dst);
		} catch (e:Dynamic) {
			throw 'Copy failed: $e';
		}
		if (platform != BuildPlatform.WINDOWS) {
			Sys.command("chmod", ["+x", dst]);
		}
		try {
			FileSystem.deleteFile(obj);
		} catch (_:Dynamic) {}
	}

	private static function finalizePHP(outDir:String, appFile:String):Void {
		var source = Path.join([outDir, "index.php"]);
		var target = Path.join([outDir, appFile + ".php"]);
		if (!FileSystem.exists(source)) {
			throw 'Expected PHP entrypoint missing: $source';
		}
		try {
			File.copy(source, target);
		} catch (e:Dynamic) {
			throw 'Copy failed: $e';
		}
		try {
			FileSystem.deleteFile(source);
		} catch (_:Dynamic) {}
	}

	private static function deleteRecursive(path:String):Void {
		if (!FileSystem.exists(path)) {
			return;
		}

		if (FileSystem.isDirectory(path)) {
			for (entry in FileSystem.readDirectory(path)) {
				deleteRecursive(Path.join([path, entry]));
			}
			FileSystem.deleteDirectory(path);
			return;
		}

		FileSystem.deleteFile(path);
	}

	private static function findFileRecursive(root:String, fileName:String):Null<String> {
		if (!FileSystem.exists(root)) {
			return null;
		}

		for (entry in FileSystem.readDirectory(root)) {
			var path = Path.join([root, entry]);
			if (FileSystem.isDirectory(path)) {
				var nested = findFileRecursive(path, fileName);
				if (nested != null) {
					return nested;
				}
				continue;
			}

			if (entry == fileName) {
				return path;
			}
		}

		return null;
	}
}
