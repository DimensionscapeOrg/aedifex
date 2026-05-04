package aedifex.cli;

import aedifex.AedifexInfo;
import aedifex.build.BuildArchitecture;
import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.build.Profile;
import aedifex.build.ProjectSpec;
import aedifex.build.ProjectSpec.ExtensionCapabilities;
import aedifex.build.ProjectSpec.ExtensionSpec;
import aedifex.build.ProjectSpec.HaxelibSpec;
import aedifex.build.ProjectSpec.TaskSpec;
import aedifex.build._internal.ExecutionPlanner;
import aedifex.build._internal.ToolEnvironment;
import aedifex.core.BuildContext;
import aedifex.core.Builder;
import aedifex.core.Runner;
import aedifex.display.DisplayTools;
import aedifex.plugin.PluginManager;
import aedifex.release.ReleaseTools;
import aedifex.setup.SetupStatus;
import aedifex.setup.TargetSetup;
import aedifex.util.ANSI;
import aedifex.util.Intro;
import aedifex.theme.Themes;
import aedifex.config.Loader;
import haxe.Json;
import haxe.Resource;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class Main {
	public static var plugins:PluginManager;
	private static inline final IMPLICIT_TOOL_HAXELIB = "aedifex";
	private static inline final LIME_EXTENSION_CLASS = "aedifex.lime.LimeExtension";
	private static inline final GRAPHAXE_EXTENSION_CLASS = "aedifex.graphaxe.GraphaxeExtension";

	private static var currentTheme:String;
	private static var quiet:Bool = false;
	private static var ignoreQuestions:Bool = false;
	private static var invocationCwd:String;
	private static inline final USER_CFG_DIR = ".aedifex";
	private static inline final USER_CFG_FILE = "config.json";
	private static var helpMessageText:String = 'Aedifex: extensible Haxe build tool

Daily use:
  aedifex create <path> [-plugin] [-library]
  aedifex build <target> [projectPath] [-clean] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final] [-ignore]
  aedifex clean [target] [projectPath] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final]
  aedifex run <target> [projectPath] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final] [-ignore]
  aedifex test <target> [projectPath] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final] [-ignore]

Tool:
  aedifex rebuild
  aedifex extension [rebuild|package]
  aedifex setup [status|remove]
  aedifex setup <target> [-android|-ios|-html5|-node] [-check] [-json]

Targets:
  cpp | hl | neko | jvm | php | js

Qualifiers:
  android | ios | html5 | node

Profiles:
  debug     Fast iteration
  release   Standard optimized build
  final     Release build with finalization hooks

More:
  aedifex help all
  aedifex help internals
  aedifex build cpp . -debug
  aedifex build cpp . -clean -release
  aedifex build js . -node
  aedifex build cpp . -ios -final';

	private static var fullHelpMessageText:String = 'Aedifex: extensible Haxe build tool

Project:
  aedifex create <path> [-plugin] [-library]
  aedifex build <target> [projectPath] [-clean] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final|-profile PROFILE] [-ignore] [-define KEY[=VAL]]... [-lib LIB]... [-plugins <dir>]
  aedifex clean [target] [projectPath] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final|-profile PROFILE]
  aedifex run <target> [projectPath] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final|-profile PROFILE] [-ignore] [-plugins <dir>]
  aedifex test <target> [projectPath] [-android|-ios|-html5|-node] [-x86|-x64|-arm64|-armv7] [-debug|-release|-final|-profile PROFILE] [-ignore] [-plugins <dir>]

Tool:
  aedifex rebuild
  aedifex extension [rebuild|package]
  aedifex setup [status|remove]
  aedifex setup <target> [-android|-ios|-html5|-node] [-check] [-json]

Inspect:
  aedifex explain [projectPath] [-target TARGET] [-platform PLATFORM] [-arch ARCH] [-debug|-release|-final|-profile PROFILE] [-json]
  aedifex targets [projectPath] [-json]
  aedifex profiles [-json]
  aedifex tasks [projectPath] [-json]
  aedifex task <name> <projectPath>

Package:
  aedifex haxelib sync [projectPath]
  aedifex haxelib check [projectPath]
  aedifex haxelib export [projectPath]
  aedifex release package [projectPath] [-validate]
  aedifex release validate <zipPath>

Plugins:
  aedifex plugins list
  aedifex plugins path [-set <dir>]

Global flags:
  -quiet             Suppress the banner for compact or machine-driven output
  -theme <name>      Select banner theme, or use `-theme` alone to choose interactively
  -plugins <dir>     Override plugin root for this invocation
  -ignore            Suppress interactive questions and fail cleanly instead

Profiles:
  -debug | -release | -final
  -profile <name>

Targets:
  cpp | hl | neko | jvm | php | js

Qualifiers:
  -android | -ios | -html5 | -node

Architecture:
  -x86 | -x64 | -arm64 | -armv7

Notes:
  Library and framework roots do not need a build step to publish metadata.
  Use `aedifex haxelib sync` or `aedifex haxelib export` to materialize
  `haxelib.json` from the metadata declared in `Aedifex.hx`.
  Use `-final` when you want finalization hooks and final-profile output.
  Use `-clean` when you want `build` or `test` to rebuild from a clean output directory.';

	private static var internalsHelpMessageText:String = 'Aedifex internals

These commands exist for editor integration and machine-readable tooling:

  aedifex display sync [projectPath] [-json]
  aedifex build-plan <target> [projectPath] [-platform PLATFORM] [-arch ARCH] [-debug|-release|-final|-profile PROFILE] [-json]
  aedifex launch-plan <target> [projectPath] [-platform PLATFORM] [-arch ARCH] [-debug|-release|-final|-profile PROFILE] [-json]

Most people should use:

  aedifex build <target> [projectPath]
  aedifex run <target> [projectPath]
  aedifex test <target> [projectPath]';

	public static function main():Void {
		var args = normalizeInvocationArgs(Sys.args());
		if (args.length > 0 && (args[0] == "-clean" || args[0] == "--clean")) {
			args[0] = "clean";
		}

		#if cpp
		ANSI.forceVT(true);
		ConsoleMode.enable();
		#end

		currentTheme = "cyber";
		var i = 0;
		while (i < args.length) {
			var arg = args[i];
			if (arg == "-quiet" || arg == "--quiet") {
				quiet = true;
				args.splice(i, 1);
				continue;
			}
			if (arg == "-ignore" || arg == "--ignore") {
				ignoreQuestions = true;
				args.splice(i, 1);
				continue;
			}
			if (arg == "-theme" || arg == "--theme") {
				var themeName = if (i + 1 < args.length && !StringTools.startsWith(args[i + 1], "-")) {
					var value = args[i + 1];
					args.splice(i, 2);
					value;
				} else {
					args.splice(i, 1);
					chooseThemeInteractively();
				}
				if (themeName != null) {
					currentTheme = resolveThemeName(themeName);
				}
				continue;
			}
			if (StringTools.startsWith(arg, "-theme=") || StringTools.startsWith(arg, "--theme=")) {
				var prefix = StringTools.startsWith(arg, "-theme=") ? "-theme=" : "--theme=";
				var themeName = arg.substr(prefix.length);
				currentTheme = resolveThemeName(themeName);
				args.splice(i, 1);
				continue;
			}
			i++;
		}

		if (args.length == 0) {
			if (!quiet) {
				Intro.show(AedifexInfo.version, currentTheme);
			}
			return welcome();
		}

		var cmd = args[0].toLowerCase();
		quiet = quiet || shouldSuppressBanner(cmd, args);
		if (!quiet) {
			Intro.show(AedifexInfo.version, currentTheme);
		}

		try {
			switch (cmd) {
				case "build":
					ensurePlugins(resolvePluginsPath(args));
					doBuild(args);
				case "run":
					ensurePlugins(resolvePluginsPath(args));
					doRun(args);
				case "test":
					ensurePlugins(resolvePluginsPath(args));
					doTest(args);
				case "create":
					doCreate(args);
				case "setup":
					doSetup(args);
				case "rebuild":
					doToolRebuild(args);
				case "extension":
					doExtension(args);
				case "clean":
					ensurePlugins(resolvePluginsPath(args));
					doClean(args);
				case "explain":
					doExplain(args);
				case "targets":
					doTargets(args);
				case "profiles":
					doProfiles(args);
				case "tasks":
					doTasks(args);
				case "task":
					doTask(args);
				case "haxelib":
					doHaxelib(args);
				case "release":
					doRelease(args);
				case "display":
					doDisplay(args);
				case "build-plan":
					doBuildPlan(args);
				case "launch-plan":
					doLaunchPlan(args);
				case "plugins":
					var pluginsRoot = resolvePluginsPath(args);
					ensurePlugins(pluginsRoot);
					doPlugins(args, pluginsRoot);
				case "help", "-h", "--help":
					help(args);
				default:
					help(null, 'Unknown command: $cmd');
			}
		} catch (e:Dynamic) {
			Sys.println('[Aedifex] ' + Std.string(e));
			Sys.exit(1);
		}
	}

	private static function ensurePlugins(root:String):Void {
		if (plugins == null) {
			plugins = new PluginManager(root);
		}
	}

	private static function normalizeInvocationArgs(args:Array<String>):Array<String> {
		invocationCwd = Path.normalize(Sys.getCwd());
		if (Sys.getEnv("HAXELIB_RUN") != "1" || args.length == 0) {
			return args;
		}

		var candidate = args[args.length - 1];
		if (!FileSystem.exists(candidate) || !FileSystem.isDirectory(candidate)) {
			return args;
		}

		invocationCwd = Path.normalize(candidate);
		var normalized = args.copy();
		normalized.pop();
		return normalized;
	}

	private static function shouldSuppressBanner(cmd:String, args:Array<String>):Bool {
		if (hasFlag(args, "-json") || hasFlag(args, "--json") || cmd == "profiles") {
			return true;
		}
		return cmd == "haxelib" && args.length > 1 && (args[1] == "export" || args[1] == "print");
	}

	private static function hasFlag(args:Array<String>, flag:String):Bool {
		for (arg in args) {
			if (arg == flag) return true;
		}
		return false;
	}

	private static function resolveThemeName(themeName:String):String {
		if (themeName == null) {
			throw "Theme name is required.";
		}
		var normalized = StringTools.trim(themeName);
		if (normalized.length == 0) {
			throw "Theme name is required.";
		}
		if (!Themes.themeRegistry.exists(normalized)) {
			throw 'Unknown theme: ${normalized}.';
		}
		return normalized;
	}

	private static function chooseThemeInteractively():String {
		var names = availableThemeNames();
		if (names.length == 0) {
			throw "No themes are registered.";
		}
		if (ignoreQuestions || !canAskQuestions()) {
			throw "Theme selection requires a theme name. Available themes: " + names.join(", ");
		}
		Sys.println("Available themes:");
		for (index in 0...names.length) {
			Sys.println("  " + (index + 1) + ". " + names[index]);
		}
		Sys.println("Select a theme by number:");
		Sys.print("> ");
		var answer = try {
			StringTools.trim(Sys.stdin().readLine());
		} catch (_:Dynamic) {
			"";
		}
		if (answer.length == 0) {
			throw "Theme selection cancelled.";
		}
		var choice = Std.parseInt(answer);
		if (choice == null || choice < 1 || choice > names.length) {
			throw "Invalid theme selection.";
		}
		return names[choice - 1];
	}

	private static function availableThemeNames():Array<String> {
		var names:Array<String> = [];
		for (name in Themes.themeRegistry.keys()) {
			names.push(name);
		}
		names.sort(function(a, b) return Reflect.compare(a, b));
		return names;
	}

	private static function doPlugins(args:Array<String>, currentRoot:String):Void {
		if (args.length < 2) {
			Sys.println("plugins commands: list | path [-set <dir>]");
			return;
		}

		switch (args[1]) {
			case "list":
				var names = plugins.listNames();
				if (names.length == 0) {
					Sys.println("(no plugins found in: " + currentRoot + ")");
				} else {
					Sys.println("Plugins in " + currentRoot + ":");
					for (n in names) {
						Sys.println("  - " + n);
					}
				}

			case "path":
				var setTo:Null<String> = null;
				var i = 2;
				while (i < args.length) {
					var a = args[i];
					if (a == "-set" || a == "--set") {
						if (i + 1 >= args.length) throw "-set requires <dir>";
						setTo = Path.normalize(args[i + 1]);
						i++;
					} else {
						throw 'Unknown flag: $a';
					}
					i++;
				}
				if (setTo == null) {
					Sys.println(currentRoot);
				} else {
					if (!FileSystem.exists(setTo)) FileSystem.createDirectory(setTo);
					saveUserPluginsPath(setTo);
					Sys.println("Plugins path set to: " + setTo);
				}

			default:
				Sys.println("plugins commands: list | path [-set <dir>]");
		}
	}

	private static function doCreate(args:Array<String>):Void {
		if (args.length < 2) throw "create requires <path>";

		var isPlugin = false;
		var isLibrary = false;
		for (i in 2...args.length) {
			var a = args[i];
			if (a == "-plugin" || a == "--plugin" || a == "-p") {
				isPlugin = true;
			} else if (a == "-library" || a == "--library" || a == "-l") {
				isLibrary = true;
			}
		}

		var projectPath = resolveUserPath(args[1]);
		var norm = Path.normalize(projectPath);
		var li = norm.lastIndexOf("/") + 1;
		var name = norm.substr(li);

		ensureDir(projectPath);
		ensureDir(Path.join([projectPath, "src"]));
		ensureDir(Path.join([projectPath, "bin"]));

		if (isPlugin) {
			var pluginDir = Path.join([projectPath, "src", "aedifex", "plugin"]);
			ensureDir(Path.join([projectPath, "src", "aedifex"]));
			ensureDir(pluginDir);

			var wireSrc = Resource.getString("PluginWire");
			if (wireSrc == null) throw "Missing resource: PluginWire";
			File.saveContent(Path.join([projectPath, "src", "aedifex", "plugin", "PluginWire.hx"]), wireSrc);
			Sys.println("New plugin project created at: " + projectPath);
		}

		if (!isLibrary) {
			var mainT = Resource.getString("main-template");
			if (mainT == null) throw "Missing resource: main-template";
			File.saveContent(Path.join([projectPath, "src", "Main.hx"]), mainT);
		}

		var definesT = Resource.getString("project-defines-template");
		if (definesT == null) throw "Missing resource: project-defines-template";
		File.saveContent(Path.join([projectPath, "ProjectDefines.hx"]), definesT);

		var projectT = Resource.getString(isLibrary ? "aedifex-library-template" : "aedifex-template");
		if (projectT == null) throw "Missing resource: " + (isLibrary ? "aedifex-library-template" : "aedifex-template");
		projectT = StringTools.replace(projectT, "DefaultApplication", name);
		projectT = StringTools.replace(projectT, "default-library", name);
		File.saveContent(Path.join([projectPath, "Aedifex.hx"]), projectT);

		Sys.println("New project created at: " + projectPath);
	}

	private static function doSetup(args:Array<String>):Void {
		if (args.length > 1 && isCliSetupAction(args[1])) {
			CliSetup.run(args.slice(1));
			return;
		}

		if (args.length > 1) {
			doTargetSetup(args);
			return;
		}

		CliSetup.run([]);
	}

	private static function doToolRebuild(args:Array<String>):Void {
		if (args.length > 1) {
			var mode = args[1].toLowerCase();
			if (mode != "runner") {
				throw "rebuild does not take a target. It rebuilds the active Aedifex runner.";
			}
		}

		var root = ToolEnvironment.getInstalledLibraryRoot();
		if (root == null) {
			root = ToolEnvironment.getAedifexRoot();
		}
		Sys.println("Rebuilding Aedifex runner...");
		var runnerCode = runCommandIn(root, "haxe", ["run.hxml"]);
		if (runnerCode != 0) {
			throw "Runner rebuild failed with exit " + runnerCode;
		}
		Sys.println("Runner rebuild complete.");

		Sys.println("Rebuild complete for " + root);
	}

	private static function doExtension(args:Array<String>):Void {
		ExtensionTools.run(args.length > 1 ? args.slice(1) : []);
	}

	private static function doClean(args:Array<String>):Void {
		var parsed = parseOptionalTargetCommand(args, 1);
		var options = parseExecutionOptions(args, parsed.nextIndex, Profile.RELEASE, false);
		var projectPath = options.projectPath != null ? resolveUserPath(options.projectPath) : invocationCwd;
		var project = Loader.loadProject(projectPath);
		var target = parsed.target != null ? parsed.target : ExecutionPlanner.defaultTarget(project);
		if (target == null) {
			throw "clean requires a target, or a project with a default target.";
		}
		if (tryRunGraphaxeDelegatedLifecycle("clean", project, target, options.platform, options.architecture, options.profile, projectPath, false)
			|| tryRunLimeDelegatedLifecycle("clean", project, target, options.platform, options.architecture, options.profile, projectPath, false)) {
			var delegatedContext = createContext(projectPath, project, target, options.platform, options.architecture, options.profile);
			Sys.println("Clean complete: " + delegatedContext.outDir);
			return;
		}

		var cleanedPath = Builder.clean(project, target, options.platform, options.architecture, options.profile, projectPath);
		Sys.println("Clean complete: " + cleanedPath);
	}

	private static function doTargetSetup(args:Array<String>):Void {
		var target = ExecutionPlanner.normalizeTarget(args[1]);
		var options = parseSetupOptions(args, 2);
		var status = TargetSetup.run(target, options.platform, options.checkOnly);
		if (options.json) {
			printJson(status.toDynamic());
			if (!status.ready) Sys.exit(1);
			return;
		}

		Sys.println("Setting up `" + Std.string(status.target) + "`" + (status.platform != null ? " for `" + Std.string(status.platform) + "`" : "") + "...");
		for (item in status.installed) {
			Sys.println("Installed `" + item + "`.");
		}
		for (item in status.detected) {
			Sys.println("Detected `" + item + "`.");
		}
		for (item in status.manualSteps) {
			Sys.println(item);
		}
		if (status.ready) {
			Sys.println("Setup complete.");
			return;
		}

		throw setupFailureMessage(status);
	}

	private static function runCommandIn(cwd:String, exe:String, commandArgs:Array<String>):Int {
		var previous = Sys.getCwd();
		var failure:Dynamic = null;
		var exitCode = -1;
		try {
			Sys.setCwd(cwd);
			exitCode = Sys.command(exe, commandArgs);
		} catch (e:Dynamic) {
			failure = e;
		}
		Sys.setCwd(previous);
		if (failure != null) {
			throw failure;
		}
		return exitCode;
	}

	private static function doExplain(args:Array<String>):Void {
		var options = parseReadOptions(args, 1);
		var projectPath = options.projectPath != null ? resolveUserPath(options.projectPath) : invocationCwd;
		var project = Loader.loadProject(projectPath);
		var defaultTarget = ExecutionPlanner.defaultTarget(project);
		var defaultPlatform = defaultTarget != null ? ExecutionPlanner.defaultPlatform(project, defaultTarget) : null;
		var defaultArchitecture = defaultTarget != null ? ExecutionPlanner.defaultArchitecture(project, defaultTarget, defaultPlatform) : null;
		var payload:Dynamic = {
			projectRoot: Path.normalize(projectPath),
			kind: Std.string(project.kind),
			host: ExecutionPlanner.hostInfo(),
			defaults: {
				target: defaultTarget != null ? Std.string(defaultTarget) : null,
				platform: defaultPlatform != null ? Std.string(defaultPlatform) : null,
				architecture: defaultArchitecture != null ? Std.string(defaultArchitecture) : null,
				profile: Std.string(ExecutionPlanner.defaultProfile(project))
			},
			extensions: describeExtensions(project.extensions),
			extensionCapabilities: summarizeExtensionCapabilities(project.extensions),
			provides: summarizeProvides(project),
			targets: ExecutionPlanner.allTargetInfos(project),
			project: project
		};

		if (options.target != null) {
			var selectedPlan:Dynamic = ExecutionPlanner.buildPlan(projectPath, project, options.target, options.platform, options.architecture, options.profile);
			selectedPlan.extensions = describeExtensions((cast selectedPlan.project : ProjectSpec).extensions);
			selectedPlan.extensionCapabilities = summarizeExtensionCapabilities((cast selectedPlan.project : ProjectSpec).extensions);
			payload.selected = selectedPlan;
		}

		printJson(payload);
	}

	private static function hasExplicitProjectPath(args:Array<String>, startIndex:Int):Bool {
		for (i in startIndex...args.length) {
			if (!StringTools.startsWith(args[i], "-")) {
				return true;
			}
		}
		return false;
	}

	private static function doTargets(args:Array<String>):Void {
		var projectPath = parseSimpleProjectPath(args, 1);
		var project = Loader.loadProject(projectPath);
		var defaultTarget = ExecutionPlanner.defaultTarget(project);
		var defaultPlatform = defaultTarget != null ? ExecutionPlanner.defaultPlatform(project, defaultTarget) : null;
		var defaultArchitecture = defaultTarget != null ? ExecutionPlanner.defaultArchitecture(project, defaultTarget, defaultPlatform) : null;
		printJson({
			projectRoot: Path.normalize(projectPath),
			kind: Std.string(project.kind),
			host: ExecutionPlanner.hostInfo(),
			defaultTarget: defaultTarget != null ? Std.string(defaultTarget) : null,
			defaultPlatform: defaultPlatform != null ? Std.string(defaultPlatform) : null,
			defaultArchitecture: defaultArchitecture != null ? Std.string(defaultArchitecture) : null,
			extensions: describeExtensions(project.extensions),
			extensionCapabilities: summarizeExtensionCapabilities(project.extensions),
			provides: summarizeProvides(project),
			targets: ExecutionPlanner.allTargetInfos(project)
		});
	}

	private static function doProfiles(args:Array<String>):Void {
		printJson({
			defaultProfile: Std.string(Profile.DEBUG),
			profiles: [
				{name: Std.string(Profile.DEBUG), description: "Fast iteration with debug symbols and debugger-friendly defines."},
				{name: Std.string(Profile.RELEASE), description: "Optimized normal build for regular local and CI usage."},
				{name: Std.string(Profile.FINAL), description: "Production-oriented build profile with finalize lifecycle hooks."}
			]
		});
	}

	private static function doTasks(args:Array<String>):Void {
		var projectPath = parseSimpleProjectPath(args, 1);
		var project = Loader.loadProject(projectPath);
		var resolved = aedifex.build._internal.ProjectResolver.resolve(project);
		printJson({
			projectRoot: Path.normalize(projectPath),
			kind: Std.string(resolved.kind),
			tasks: [for (task in resolved.tasks) describeTask(task)]
		});
	}

	private static function doTask(args:Array<String>):Void {
		if (args.length < 3) throw "task requires <name> <projectPath>";
		var taskName = args[1];
		var projectPath = resolveUserPath(args[2]);
		var project = Loader.loadProject(projectPath);
		var resolved = aedifex.build._internal.ProjectResolver.resolve(project);
		var task = findTask(resolved.tasks, taskName);
		if (task == null) {
			throw 'Unknown task `${taskName}`.';
		}
		runNamedTask(task, projectPath);
	}

	private static function doHaxelib(args:Array<String>):Void {
		if (args.length < 2) throw "haxelib commands: sync | check | export [projectPath]";
		switch (args[1]) {
			case "sync":
				var projectPath = parseSimpleProjectPath(args, 2);
				var existingPath = Path.join([projectPath, "haxelib.json"]);
				var base:Dynamic = null;
				if (FileSystem.exists(existingPath)) {
					base = Json.parse(File.getContent(existingPath));
				}
				var content = renderHaxelibJson(projectPath, base);
				File.saveContent(Path.join([projectPath, "haxelib.json"]), content);
				Sys.println("Synced haxelib.json from Aedifex.hx metadata.");
			case "check":
				var projectPath = parseSimpleProjectPath(args, 2);
				var targetPath = Path.join([projectPath, "haxelib.json"]);
				if (!FileSystem.exists(targetPath)) {
					throw "haxelib.json is missing. Run `aedifex haxelib sync` to generate it from Aedifex.hx.";
				}
				var actualContent = File.getContent(targetPath);
				var expected = renderHaxelibJson(projectPath, Json.parse(actualContent));
				var actual = normalizeJson(actualContent);
				if (actual != expected) {
					throw "haxelib.json is out of sync with Aedifex.hx. Run `aedifex haxelib sync`.";
				}
				Sys.println("haxelib.json is in sync with Aedifex.hx metadata.");
			case "export", "print":
				var projectPath = parseSimpleProjectPath(args, 2);
				Sys.println(renderHaxelibJson(projectPath));
			default:
				throw "haxelib commands: sync | check | export [projectPath]";
		}
	}

	private static function doRelease(args:Array<String>):Void {
		if (args.length < 2) throw "release commands: package [projectPath] [-validate] | validate <zipPath>";
		switch (args[1]) {
			case "package":
				var validate = false;
				for (i in 2...args.length) {
					if (args[i] == "-validate" || args[i] == "--validate") {
						validate = true;
					}
				}
				var projectPath = parseSimpleProjectPath(args, 2, ["-validate", "--validate"]);
				var zipPath = ReleaseTools.packageHaxelib(projectPath, validate);
				Sys.println("Created haxelib release package: " + zipPath);
			case "validate":
				if (args.length < 3) throw "release validate requires <zipPath>";
				ReleaseTools.validateHaxelibPackage(resolveUserPath(args[2]));
				Sys.println("Validated haxelib release package: " + resolveUserPath(args[2]));
			default:
				throw "release commands: package [projectPath] [-validate] | validate <zipPath>";
		}
	}

	private static function doDisplay(args:Array<String>):Void {
		if (args.length < 2) {
			throw "display commands: sync [projectPath] [-json]";
		}

		switch (args[1]) {
			case "sync":
				var options = parseSimpleProjectPathAndJson(args, 2);
				var result = DisplayTools.sync(options.projectPath);
				if (options.json) {
					printJson(result);
				} else {
					Sys.println("Synced Aedifex display support:");
					Sys.println("  " + Path.join([result.projectRoot, result.hxmlPath]));
				}
			default:
				throw "display commands: sync [projectPath] [-json]";
		}
	}

	private static function doBuildPlan(args:Array<String>):Void {
		if (args.length < 2) throw "build-plan requires <target> [projectPath]";
		var target = ExecutionPlanner.normalizeTarget(args[1]);
		var options = parseExecutionOptions(args, 2, Profile.RELEASE, false);
		var projectPath = options.projectPath != null ? resolveUserPath(options.projectPath) : invocationCwd;
		var project = Loader.loadProject(projectPath);
		var plan = ExecutionPlanner.buildPlan(projectPath, project, target, options.platform, options.architecture, options.profile);
		printJson(applyDelegatedPlan(project, target, options.platform, options.architecture, options.profile, projectPath, plan));
	}

	private static function doLaunchPlan(args:Array<String>):Void {
		if (args.length < 2) throw "launch-plan requires <target> [projectPath]";
		var target = ExecutionPlanner.normalizeTarget(args[1]);
		var options = parseExecutionOptions(args, 2, Profile.RELEASE, false);
		var projectPath = options.projectPath != null ? resolveUserPath(options.projectPath) : invocationCwd;
		var project = Loader.loadProject(projectPath);
		var plan = ExecutionPlanner.launchPlan(projectPath, project, target, options.platform, options.architecture, options.profile);
		printJson(applyDelegatedPlan(project, target, options.platform, options.architecture, options.profile, projectPath, plan));
	}

	private static function doBuild(args:Array<String>):Void {
		if (args.length < 2) throw "build requires <target> [projectPath]";
		var target = ExecutionPlanner.normalizeTarget(args[1]);
		var options = parseExecutionOptions(args, 2, Profile.RELEASE, true);
		var projectPath = options.projectPath != null ? resolveUserPath(options.projectPath) : invocationCwd;
		var project = Loader.loadProject(projectPath);
		ensureTargetReady(project, target, options.platform, options.ignoreSetup);
		if (tryRunGraphaxeDelegatedLifecycle("build", project, target, options.platform, options.architecture, options.profile, projectPath, options.cleanBuild)
			|| tryRunLimeDelegatedLifecycle("build", project, target, options.platform, options.architecture, options.profile, projectPath, options.cleanBuild)) {
			Sys.println("Build complete.");
			return;
		}
		if (options.cleanBuild) {
			runRebuildLifecycle(project, target, options.platform, options.architecture, options.profile, projectPath, options.extraDefs, options.extraLibs);
		} else {
			runBuildLifecycle(project, target, options.platform, options.architecture, options.profile, projectPath, options.extraDefs, options.extraLibs);
		}

		Sys.println("Build complete.");
	}

	private static function doRun(args:Array<String>):Void {
		if (args.length < 2) throw "run requires <target> [projectPath]";
		var target = ExecutionPlanner.normalizeTarget(args[1]);
		var options = parseExecutionOptions(args, 2, Profile.RELEASE, false);
		var projectPath = options.projectPath != null ? resolveUserPath(options.projectPath) : invocationCwd;
		var project = Loader.loadProject(projectPath);
		ensureTargetReady(project, target, options.platform, options.ignoreSetup);
		if (tryRunGraphaxeDelegatedLifecycle("run", project, target, options.platform, options.architecture, options.profile, projectPath, false)
			|| tryRunLimeDelegatedLifecycle("run", project, target, options.platform, options.architecture, options.profile, projectPath, false)) {
			return;
		}
		var ctx = createContext(projectPath, project, target, options.platform, options.architecture, options.profile);
		plugins.preRun(ctx);
		Runner.run(project, target, options.platform, options.architecture, options.profile, projectPath);
		plugins.postRun(ctx);
	}

	private static function doTest(args:Array<String>):Void {
		if (args.length < 2) throw "test requires <target> [projectPath]";
		var target = ExecutionPlanner.normalizeTarget(args[1]);
		var options = parseExecutionOptions(args, 2, Profile.DEBUG, true);
		var projectPath = options.projectPath != null ? resolveUserPath(options.projectPath) : invocationCwd;
		var project = Loader.loadProject(projectPath);
		ensureTargetReady(project, target, options.platform, options.ignoreSetup);
		if (tryRunGraphaxeDelegatedLifecycle("test", project, target, options.platform, options.architecture, options.profile, projectPath, options.cleanBuild)
			|| tryRunLimeDelegatedLifecycle("test", project, target, options.platform, options.architecture, options.profile, projectPath, options.cleanBuild)) {
			return;
		}

		var buildCtx = createContext(projectPath, project, target, options.platform, options.architecture, options.profile);
		plugins.preBuild(buildCtx);
		var builtContext = options.cleanBuild
			? Builder.rebuild(project, target, options.platform, options.architecture, options.profile, projectPath, options.extraDefs, options.extraLibs)
			: Builder.build(project, target, options.platform, options.architecture, options.profile, projectPath, options.extraDefs, options.extraLibs);
		plugins.postBuild(builtContext);
		plugins.preRun(buildCtx);
		Runner.run(project, target, options.platform, options.architecture, options.profile, projectPath);
		plugins.postRun(buildCtx);
	}

	private static function runBuildLifecycle(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectPath:String,
		extraDefs:Array<String>,
		extraLibs:Array<String>
	):BuildContext {
		var plannedContext = createContext(projectPath, project, target, platform, architecture, profile);
		if (profile == Profile.FINAL) {
			plugins.preFinalize(plannedContext);
		}
		plugins.preBuild(plannedContext);
		var buildContext = Builder.build(project, target, platform, architecture, profile, projectPath, extraDefs, extraLibs);
		plugins.postBuild(buildContext);
		if (profile == Profile.FINAL) {
			Builder.runHooks(buildContext.project.hooks, aedifex.build.ProjectSpec.BuildPhase.PRE_FINALIZE, projectPath);
			Builder.runHooks(buildContext.project.hooks, aedifex.build.ProjectSpec.BuildPhase.POST_FINALIZE, projectPath);
			plugins.postFinalize(buildContext);
		}
		return buildContext;
	}

	private static function runRebuildLifecycle(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectPath:String,
		extraDefs:Array<String>,
		extraLibs:Array<String>
	):BuildContext {
		var plannedContext = createContext(projectPath, project, target, platform, architecture, profile);
		if (profile == Profile.FINAL) {
			plugins.preFinalize(plannedContext);
		}
		plugins.preBuild(plannedContext);
		var buildContext = Builder.rebuild(project, target, platform, architecture, profile, projectPath, extraDefs, extraLibs);
		plugins.postBuild(buildContext);
		if (profile == Profile.FINAL) {
			Builder.runHooks(buildContext.project.hooks, aedifex.build.ProjectSpec.BuildPhase.PRE_FINALIZE, projectPath);
			Builder.runHooks(buildContext.project.hooks, aedifex.build.ProjectSpec.BuildPhase.POST_FINALIZE, projectPath);
			plugins.postFinalize(buildContext);
		}
		return buildContext;
	}

	private static function parseOptionalTargetCommand(args:Array<String>, startIndex:Int):{target:Null<BuildTarget>, nextIndex:Int} {
		if (args.length <= startIndex) {
			return {target: null, nextIndex: startIndex};
		}
		var candidate = args[startIndex];
		if (candidate == null || candidate.length == 0 || StringTools.startsWith(candidate, "-")) {
			return {target: null, nextIndex: startIndex};
		}
		try {
			return {
				target: ExecutionPlanner.normalizeTarget(candidate),
				nextIndex: startIndex + 1
			};
		} catch (_:Dynamic) {
			return {target: null, nextIndex: startIndex};
		}
	}

	private static function isCliSetupAction(value:String):Bool {
		var normalized = StringTools.trim(value).toLowerCase();
		return switch (normalized) {
			case "status", "--status", "remove", "--remove", "uninstall", "--uninstall":
				true;
			default:
				false;
		}
	}

	private static function parseExecutionOptions(
		args:Array<String>,
		startIndex:Int,
		defaultProfile:Profile,
		allowBuildFlags:Bool
	):{profile:Profile, platform:BuildPlatform, architecture:BuildArchitecture, extraDefs:Array<String>, extraLibs:Array<String>, projectPath:Null<String>, cleanBuild:Bool, ignoreSetup:Bool} {
		var profile = defaultProfile;
		var platform:BuildPlatform = null;
		var architecture:BuildArchitecture = null;
		var extraDefs:Array<String> = [];
		var extraLibs:Array<String> = [];
		var projectPath:Null<String> = null;
		var cleanBuild = false;
		var ignoreSetup = false;
		var i = startIndex;
		var consumedProjectPath = false;

		while (i < args.length) {
			var a = args[i];
			switch (a) {
				case "-debug", "--debug":
					profile = Profile.DEBUG;
				case "-release", "--release":
					profile = Profile.RELEASE;
				case "-final", "--final":
					profile = Profile.FINAL;
				case "-profile", "--profile":
					if (i + 1 >= args.length) throw "-profile requires PROFILE";
					profile = Profile.normalize(args[++i]);
				case "-platform", "--platform":
					if (i + 1 >= args.length) throw "-platform requires PLATFORM";
					platform = ExecutionPlanner.normalizePlatform(args[++i]);
				case "-arch", "--arch":
					if (i + 1 >= args.length) throw "-arch requires ARCH";
					architecture = ExecutionPlanner.normalizeArchitecture(args[++i]);
				case "-android", "-ios", "-html5", "-node":
					platform = ExecutionPlanner.normalizePlatform(a);
				case "-x86", "-x64", "-arm64", "-armv7":
					architecture = ExecutionPlanner.normalizeArchitecture(a);
				case "-clean", "--clean":
					if (!allowBuildFlags) throw 'Unknown flag: $a';
					cleanBuild = true;
				case "-ignore", "--ignore":
					ignoreSetup = true;
				case "-plugins", "--plugins":
					if (i + 1 >= args.length) throw "-plugins requires <dir>";
					i++;
				case _ if (StringTools.startsWith(a, "-plugins=") || StringTools.startsWith(a, "--plugins=")):
				case "-define", "--define":
					if (!allowBuildFlags) throw 'Unknown flag: $a';
					if (i + 1 >= args.length) throw "-define requires KEY or KEY=VAL";
					extraDefs.push(args[++i]);
				case "-lib", "--lib":
					if (!allowBuildFlags) throw 'Unknown flag: $a';
					if (i + 1 >= args.length) throw "-lib requires LIB";
					extraLibs.push(args[++i]);
				case "-json", "--json":
				default:
					if (!StringTools.startsWith(a, "-") && !consumedProjectPath) {
						consumedProjectPath = true;
						projectPath = a;
						i++;
						continue;
					}
					throw 'Unknown flag: $a';
			}
			i++;
		}

		return {
			profile: profile,
			platform: platform,
			architecture: architecture,
			extraDefs: extraDefs,
			extraLibs: extraLibs,
			projectPath: projectPath,
			cleanBuild: cleanBuild,
			ignoreSetup: ignoreSetup
		};
	}

	private static function parseSetupOptions(
		args:Array<String>,
		startIndex:Int
	):{platform:BuildPlatform, checkOnly:Bool, json:Bool} {
		var platform:BuildPlatform = null;
		var checkOnly = false;
		var json = false;
		var i = startIndex;

		while (i < args.length) {
			var a = args[i];
			switch (a) {
				case "-android", "-ios", "-html5", "-node":
					platform = ExecutionPlanner.normalizePlatform(a);
				case "-check", "--check":
					checkOnly = true;
				case "-json", "--json":
					json = true;
				default:
					throw 'Unknown flag: $a';
			}
			i++;
		}

		return {
			platform: platform,
			checkOnly: checkOnly,
			json: json
		};
	}

	private static function parseReadOptions(
		args:Array<String>,
		startIndex:Int
	):{profile:Profile, target:Null<BuildTarget>, platform:BuildPlatform, architecture:BuildArchitecture, projectPath:Null<String>} {
		var profile = Profile.DEBUG;
		var target:Null<BuildTarget> = null;
		var platform:BuildPlatform = null;
		var architecture:BuildArchitecture = null;
		var projectPath:Null<String> = null;
		var i = startIndex;
		while (i < args.length) {
			var a = args[i];
			switch (a) {
				case "-debug", "--debug":
					profile = Profile.DEBUG;
				case "-release", "--release":
					profile = Profile.RELEASE;
				case "-final", "--final":
					profile = Profile.FINAL;
				case "-profile", "--profile":
					if (i + 1 >= args.length) throw "-profile requires PROFILE";
					profile = Profile.normalize(args[++i]);
				case "-target", "--target":
					if (i + 1 >= args.length) throw "-target requires TARGET";
					target = ExecutionPlanner.normalizeTarget(args[++i]);
				case "-platform", "--platform":
					if (i + 1 >= args.length) throw "-platform requires PLATFORM";
					platform = ExecutionPlanner.normalizePlatform(args[++i]);
				case "-arch", "--arch":
					if (i + 1 >= args.length) throw "-arch requires ARCH";
					architecture = ExecutionPlanner.normalizeArchitecture(args[++i]);
				case "-android", "-ios", "-html5", "-node":
					platform = ExecutionPlanner.normalizePlatform(a);
				case "-x86", "-x64", "-arm64", "-armv7":
					architecture = ExecutionPlanner.normalizeArchitecture(a);
				case "-json", "--json":
				case "-plugins", "--plugins":
					if (i + 1 >= args.length) throw "-plugins requires <dir>";
					i++;
				case _ if (StringTools.startsWith(a, "-plugins=") || StringTools.startsWith(a, "--plugins=")):
				default:
					if (!StringTools.startsWith(a, "-")) {
						if (projectPath == null) {
							projectPath = a;
						}
						i++;
						continue;
					}
					throw 'Unknown flag: $a';
			}
			i++;
		}
		return {profile: profile, target: target, platform: platform, architecture: architecture, projectPath: projectPath};
	}

	private static function createContext(
		projectPath:String,
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile
	):BuildContext {
		var plan = ExecutionPlanner.buildPlan(projectPath, project, target, platform, architecture, profile);
		var resolved:ProjectSpec = cast plan.project;
		var paths:Dynamic = plan.paths;
		var ctx = new BuildContext();
		ctx.projectRoot = projectPath;
		ctx.target = Std.string(target);
		ctx.backend = plan.backend;
		ctx.host = plan.host.platform;
		ctx.platform = plan.platform;
		ctx.architecture = plan.architecture;
		ctx.env = plan.platform;
		ctx.profile = Std.string(profile);
		ctx.outDir = paths.outDir;
		ctx.binDir = paths.binDir;
		ctx.objDir = paths.objDir;
		ctx.haxeDir = paths.haxeDir;
		ctx.srcDir = resolved.sources.length > 0 ? Path.join([projectPath, resolved.sources[0]]) : Path.join([projectPath, "src"]);
		ctx.defines = [for (define in resolved.defines) define.value == null ? define.name : define.name + "=" + define.value];
		ctx.libs = [for (library in resolved.libraries) library.name != null && library.name.length > 0 ? library.name : library.path];
		ctx.project = resolved;
		ctx.config = Loader.toLegacy(resolved);
		return ctx;
	}

	private static function ensureTargetReady(project:ProjectSpec, target:BuildTarget, platform:BuildPlatform, ignoreSetupPrompt:Bool):Void {
		var effectivePlatform = platform != null ? platform : ExecutionPlanner.defaultPlatform(project, target);
		var status = TargetSetup.inspect(target, effectivePlatform);
		if (status.ready) {
			return;
		}

		if (ignoreSetupPrompt || ignoreQuestions || !canAskQuestions()) {
			throw setupFailureMessage(status);
		}

		Sys.println(status.summary());
		Sys.println("Run `" + status.setupCommand + "` now? [y/n]");
		Sys.print("> ");
		var answer = try {
			StringTools.trim(Sys.stdin().readLine()).toLowerCase();
		} catch (_:Dynamic) {
			"n";
		}

		if (answer != "y" && answer != "yes") {
			throw setupFailureMessage(status);
		}

		var setupStatus = TargetSetup.run(target, effectivePlatform, false);
		for (item in setupStatus.installed) {
			Sys.println("Installed `" + item + "`.");
		}
		for (item in setupStatus.detected) {
			Sys.println("Detected `" + item + "`.");
		}
		for (item in setupStatus.manualSteps) {
			Sys.println(item);
		}
		if (!setupStatus.ready) {
			throw setupFailureMessage(setupStatus);
		}
	}

	private static function canAskQuestions():Bool {
		if (quiet) return false;
		if (Sys.getEnv("CI") != null) return false;
		if (Sys.getEnv("GITHUB_ACTIONS") != null) return false;
		if (Sys.getEnv("AEDIFEX_NONINTERACTIVE") == "1") return false;
		if (Sys.getEnv("AEDIFEX_EDITOR") == "1") return false;
		return true;
	}

	private static function setupFailureMessage(status:SetupStatus):String {
		return status.summary() + " Run `" + status.setupCommand + "`.";
	}

	private static function describeExtensions(extensions:Array<ExtensionSpec>):Array<Dynamic> {
		var results:Array<Dynamic> = [];
		for (extension in (extensions != null ? extensions : [])) {
			if (extension == null) continue;
			results.push({
				name: extension.name,
				source: extension.source,
				capabilities: cloneCapabilities(extension.capabilities)
			});
		}
		return results;
	}

	private static function summarizeExtensionCapabilities(extensions:Array<ExtensionSpec>):Dynamic {
		var defineCatalogs:Array<String> = [];
		var commands:Array<String> = [];
		var targets:Array<String> = [];
		var profiles:Array<String> = [];

		for (extension in (extensions != null ? extensions : [])) {
			if (extension == null || extension.capabilities == null) continue;
			appendUnique(defineCatalogs, extension.capabilities.defineCatalogs);
			appendUnique(commands, extension.capabilities.commands);
			appendUnique(targets, extension.capabilities.targets);
			appendUnique(profiles, extension.capabilities.profiles);
		}

		return {
			defineCatalogs: defineCatalogs,
			commands: commands,
			targets: targets,
			profiles: profiles
		};
	}

	private static function summarizeProvides(project:ProjectSpec):Dynamic {
		var provides = project != null ? project.provides : null;
		return {
			defineCatalogs: provides != null && provides.defineCatalogs != null ? provides.defineCatalogs.copy() : [],
			commands: provides != null && provides.commands != null ? provides.commands.copy() : [],
			targets: provides != null && provides.targets != null ? provides.targets.copy() : [],
			profiles: provides != null && provides.profiles != null ? provides.profiles.copy() : [],
			extensions: provides != null ? describeExtensions(provides.extensions) : []
		};
	}

	private static function describeTask(task:TaskSpec):Dynamic {
		return {
			name: task.name,
			command: task.command,
			args: task.args != null ? task.args.copy() : [],
			cwd: task.cwd,
			description: task.description
		};
	}

	private static function findTask(tasks:Array<TaskSpec>, name:String):TaskSpec {
		for (task in (tasks != null ? tasks : [])) {
			if (task != null && task.name == name) return task;
		}
		return null;
	}

	private static function runNamedTask(task:TaskSpec, projectRoot:String):Void {
		var previous = Sys.getCwd();
		var previousProjectRootEnv = Sys.getEnv("AEDIFEX_PROJECT_ROOT");
		var failure:Dynamic = null;
		try {
			Sys.putEnv("AEDIFEX_PROJECT_ROOT", projectRoot);
			Sys.setCwd(resolveTaskCwd(task.cwd, projectRoot));
			var code = Sys.command(task.command, resolveTaskArgs(task.args, projectRoot));
			if (code != 0) {
				failure = 'Task `${task.name}` failed with exit ' + code;
			}
		} catch (e:Dynamic) {
			failure = e;
		}
		Sys.putEnv("AEDIFEX_PROJECT_ROOT", previousProjectRootEnv != null ? previousProjectRootEnv : "");
		Sys.setCwd(previous);
		if (failure != null) throw failure;
	}

	private static function resolveTaskCwd(value:String, projectRoot:String):String {
		if (value == null || value.length == 0) {
			return projectRoot;
		}
		var expanded = expandTaskValue(value, projectRoot);
		return Path.isAbsolute(expanded) ? expanded : Path.join([projectRoot, expanded]);
	}

	private static function resolveTaskArgs(args:Array<String>, projectRoot:String):Array<String> {
		if (args == null) {
			return [];
		}
		return [for (arg in args) expandTaskValue(arg, projectRoot)];
	}

	private static function expandTaskValue(value:String, projectRoot:String):String {
		if (value == null) {
			return null;
		}
		return StringTools.replace(value, "$" + "{projectRoot}", projectRoot);
	}

	private static function tryRunLimeDelegatedLifecycle(
		action:String,
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectPath:String,
		cleanFirst:Bool
	):Bool {
		var extension = findExtension(project, LIME_EXTENSION_CLASS);
		if (extension == null) {
			return false;
		}

		var taskName = resolveLimeTaskName(project, extension, action, target, platform, profile);
		if (taskName == null) {
			return false;
		}

		if (cleanFirst) {
			var cleanTaskName = resolveLimeTaskName(project, extension, "clean", target, platform, profile);
			if (cleanTaskName != null) {
				var cleanTask = findTask(project.tasks, cleanTaskName);
				if (cleanTask != null) {
					runNamedTask(cleanTask, projectPath);
				}
			}
		}

		var task = findTask(project.tasks, taskName);
		if (task == null) {
			if (action == "run") {
				var fallbackTask = findTask(project.tasks, resolveLimeTaskName(project, extension, "test", target, platform, profile));
				if (fallbackTask != null) {
					var runContext = createContext(projectPath, project, target, platform, architecture, profile);
					plugins.preRun(runContext);
					runNamedTask(fallbackTask, projectPath);
					plugins.postRun(runContext);
					return true;
				}
			}
			return false;
		}

		return runDelegatedTaskLifecycle(action, task, project, target, platform, architecture, profile, projectPath);
	}

	private static function tryRunGraphaxeDelegatedLifecycle(
		action:String,
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectPath:String,
		cleanFirst:Bool
	):Bool {
		var extension = findExtension(project, GRAPHAXE_EXTENSION_CLASS);
		if (extension == null) {
			return false;
		}

		var taskName = resolveGraphaxeTaskName(project, extension, action, target, platform, profile);
		if (taskName == null) {
			return false;
		}

		if (cleanFirst) {
			var cleanTaskName = resolveGraphaxeTaskName(project, extension, "clean", target, platform, profile);
			if (cleanTaskName != null) {
				var cleanTask = findTask(project.tasks, cleanTaskName);
				if (cleanTask != null) {
					runNamedTask(cleanTask, projectPath);
				}
			}
		}

		var task = findTask(project.tasks, taskName);
		if (task == null) {
			return false;
		}

		return runDelegatedTaskLifecycle(action, task, project, target, platform, architecture, profile, projectPath);
	}

	private static function runDelegatedTaskLifecycle(
		action:String,
		task:TaskSpec,
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectPath:String
	):Bool {
		var context = createContext(projectPath, project, target, platform, architecture, profile);
		switch (action) {
			case "build":
				if (profile == Profile.FINAL) {
					plugins.preFinalize(context);
				}
				plugins.preBuild(context);
				runNamedTask(task, projectPath);
				plugins.postBuild(context);
				if (profile == Profile.FINAL) {
					plugins.postFinalize(context);
				}
			case "test":
				plugins.preBuild(context);
				runNamedTask(task, projectPath);
				plugins.postBuild(context);
			case "run":
				plugins.preRun(context);
				runNamedTask(task, projectPath);
				plugins.postRun(context);
			case "clean":
				runNamedTask(task, projectPath);
			default:
				return false;
		}
		return true;
	}

	private static function resolveLimeTaskName(
		project:ProjectSpec,
		extension:ExtensionSpec,
		action:String,
		target:BuildTarget,
		platform:BuildPlatform,
		profile:Profile
	):String {
		var prefix = "lime";
		if (extension != null && extension.options != null && Reflect.hasField(extension.options, "taskPrefix")) {
			var rawPrefix = Reflect.field(extension.options, "taskPrefix");
			if (rawPrefix != null && StringTools.trim(Std.string(rawPrefix)).length > 0) {
				prefix = StringTools.trim(Std.string(rawPrefix));
			}
		}

		var limeTarget = resolveLimeTaskTarget(project, target, platform);
		if (limeTarget == null) {
			return null;
		}

		return switch (action) {
			case "build", "test", "run":
				prefix + "-" + action + "-" + limeTarget + "-" + Std.string(profile);
			case "clean", "update", "display":
				prefix + "-" + action + "-" + limeTarget;
			default:
				null;
		};
	}

	private static function resolveLimeTaskTarget(project:ProjectSpec, target:BuildTarget, platform:BuildPlatform):String {
		var effectivePlatform = platform != null ? platform : ExecutionPlanner.defaultPlatform(project, target);
		return switch (target) {
			case BuildTarget.CPP:
				effectivePlatform != null ? Std.string(effectivePlatform) : "windows";
			case BuildTarget.JS:
				effectivePlatform == BuildPlatform.NODE ? "nodejs" : "html5";
			case BuildTarget.HL:
				"hl";
			case BuildTarget.NEKO:
				"neko";
			default:
				null;
		};
	}

	private static function resolveGraphaxeTaskName(
		project:ProjectSpec,
		extension:ExtensionSpec,
		action:String,
		target:BuildTarget,
		platform:BuildPlatform,
		profile:Profile
	):String {
		var prefix = "graphaxe";
		if (extension != null && extension.options != null && Reflect.hasField(extension.options, "taskPrefix")) {
			var rawPrefix = Reflect.field(extension.options, "taskPrefix");
			if (rawPrefix != null && StringTools.trim(Std.string(rawPrefix)).length > 0) {
				prefix = StringTools.trim(Std.string(rawPrefix));
			}
		}

		var graphaxeTarget = resolveGraphaxeTaskTarget(project, target, platform);
		if (graphaxeTarget == null) {
			return null;
		}

		return switch (action) {
			case "build", "test", "run":
				prefix + "-" + action + "-" + graphaxeTarget + "-" + Std.string(profile);
			case "clean", "update", "display":
				prefix + "-" + action + "-" + graphaxeTarget;
			default:
				null;
		};
	}

	private static function resolveGraphaxeTaskTarget(project:ProjectSpec, target:BuildTarget, platform:BuildPlatform):String {
		var effectivePlatform = platform != null ? platform : ExecutionPlanner.defaultPlatform(project, target);
		return switch (target) {
			case BuildTarget.CPP:
				effectivePlatform != null ? Std.string(effectivePlatform) : "windows";
			case BuildTarget.JS:
				effectivePlatform == BuildPlatform.NODE ? "nodejs" : "html5";
			default:
				null;
		};
	}

	private static function applyDelegatedPlan(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectPath:String,
		plan:Dynamic
	):Dynamic {
		var delegated = buildDelegatedPlanFor(project, target, platform, architecture, profile, projectPath, plan, GRAPHAXE_EXTENSION_CLASS);
		if (delegated != null) {
			return delegated;
		}
		delegated = buildDelegatedPlanFor(project, target, platform, architecture, profile, projectPath, plan, LIME_EXTENSION_CLASS);
		return delegated != null ? delegated : plan;
	}

	private static function buildDelegatedPlanFor(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectPath:String,
		plan:Dynamic,
		extensionName:String
	):Dynamic {
		if (findExtension(project, extensionName) == null) {
			return null;
		}

		var delegatedTarget = extensionName == GRAPHAXE_EXTENSION_CLASS
			? resolveGraphaxeTaskTarget(project, target, platform)
			: resolveLimeTaskTarget(project, target, platform);
		if (delegatedTarget == null) {
			return null;
		}

		var outputRoot = resolveDelegatedOutputRoot(projectPath, project);
		var outDir = Path.join([outputRoot, delegatedTarget]);
		var binDir = Path.join([outDir, "bin"]);
		var objDir = Path.join([outDir, "obj"]);
		var haxeDir = Path.join([outDir, "haxe"]);
		var fileBase = resolveDelegatedArtifactBaseName(project);
		var launcher = buildDelegatedLauncher(delegatedTarget, binDir, fileBase);
		if (launcher == null) {
			return null;
		}

		var paths = {
			outDir: outDir,
			binDir: binDir,
			objDir: objDir,
			haxeDir: haxeDir,
			artifactPath: resolveDelegatedArtifactPath(delegatedTarget, binDir, fileBase)
		};
		Reflect.setField(plan, "paths", paths);
		Reflect.setField(plan, "launcher", launcher);
		return plan;
	}

	private static function resolveDelegatedOutputRoot(projectPath:String, project:ProjectSpec):String {
		var configured = project != null && project.app != null && project.app.path != null && StringTools.trim(project.app.path).length > 0
			? StringTools.trim(project.app.path)
			: "bin";
		return Path.isAbsolute(configured) ? configured : Path.join([projectPath, configured]);
	}

	private static function resolveDelegatedArtifactBaseName(project:ProjectSpec):String {
		if (project != null && project.app != null && project.app.file != null && StringTools.trim(project.app.file).length > 0) {
			return StringTools.trim(project.app.file);
		}
		if (project != null && project.meta != null && project.meta.name != null && StringTools.trim(project.meta.name).length > 0) {
			return StringTools.trim(project.meta.name);
		}
		return "Application";
	}

	private static function resolveDelegatedArtifactPath(target:String, binDir:String, fileBase:String):String {
		var normalized = target != null ? StringTools.trim(target).toLowerCase() : "";
		return switch (normalized) {
			case "windows":
				Path.join([binDir, fileBase + ".exe"]);
			case "linux", "mac":
				Path.join([binDir, fileBase]);
			case "node", "nodejs":
				Path.join([binDir, fileBase + ".js"]);
			case "html5":
				Path.join([binDir, "index.html"]);
			default:
				binDir;
		};
	}

	private static function buildDelegatedLauncher(target:String, binDir:String, fileBase:String):Dynamic {
		var normalized = target != null ? StringTools.trim(target).toLowerCase() : "";
		return switch (normalized) {
			case "windows":
				{
					kind: "native",
					debugger: "cppvsdbg",
					command: Path.join([binDir, fileBase + ".exe"]),
					args: [],
					cwd: binDir
				};
			case "linux", "mac":
				{
					kind: "native",
					debugger: "cppdbg",
					command: Path.join([binDir, fileBase]),
					args: [],
					cwd: binDir
				};
			case "node", "nodejs":
				{
					kind: "terminal",
					debugger: null,
					command: "node",
					args: [Path.join([binDir, fileBase + ".js"])],
					cwd: binDir
				};
			case "html5":
				{
					kind: "browser",
					debugger: null,
					command: null,
					args: [],
					cwd: binDir,
					file: Path.join([binDir, "index.html"])
				};
			default:
				null;
		};
	}

	private static function findExtension(project:ProjectSpec, name:String):ExtensionSpec {
		for (extension in (project != null && project.extensions != null ? project.extensions : [])) {
			if (extension != null && extension.name == name) {
				return extension;
			}
		}
		return null;
	}

	public static function buildHaxelibJson(project:ProjectSpec, ?baseTemplate:Dynamic):String {
		var payload = buildHaxelibPayload(project, baseTemplate);
		return JsonPrinter.print(payload, null, "\t");
	}

	public static function buildHaxelibPayload(project:ProjectSpec, ?baseTemplate:Dynamic):Dynamic {
		var payload:Dynamic = defaultHaxelibTemplate();
		mergeTemplate(payload, baseTemplate);
		var haxelib = project.haxelib != null ? project.haxelib : new HaxelibSpec();
		var dependencies = buildPublishedDependencies(project);
		var contributors = (haxelib.contributors != null && haxelib.contributors.length > 0)
			? haxelib.contributors.copy()
			: (project.meta != null && project.meta.authors != null ? project.meta.authors.copy() : []);
		var classPath = resolveClassPath(project);

		setField(payload, "name", firstNonEmpty([haxelib.name, project.meta != null ? project.meta.name : null]));
		setField(payload, "url", haxelib.url);
		setField(payload, "license", haxelib.license);
		setField(payload, "tags", haxelib.tags != null ? haxelib.tags.copy() : []);
		setField(payload, "description", firstNonEmpty([haxelib.description, project.meta != null ? project.meta.description : null]));
		setField(payload, "version", firstNonEmpty([haxelib.version, project.meta != null ? project.meta.version : null]));
		setField(payload, "releasenote", haxelib.releasenote);
		setField(payload, "contributors", contributors);
		setField(payload, "dependencies", dependencies);
		setField(payload, "classPath", classPath);
		return payload;
	}

	private static function renderHaxelibJson(projectPath:String, ?baseTemplate:Dynamic):String {
		var project = Loader.loadProject(projectPath);
		var resolved = aedifex.build._internal.ProjectResolver.resolve(project);
		return buildHaxelibJson(resolved, baseTemplate);
	}

	private static function normalizeJson(content:String):String {
		var parsed:Dynamic = Json.parse(content);
		return JsonPrinter.print(parsed, null, "\t");
	}

	private static function cloneTemplate(value:Dynamic):Dynamic {
		if (value == null) {
			return {};
		}
		return Json.parse(Json.stringify(value));
	}

	private static function defaultHaxelibTemplate():Dynamic {
		return {
			name: "",
			url: "",
			license: "",
			tags: [],
			description: "",
			version: "",
			releasenote: "",
			contributors: [],
			dependencies: {},
			classPath: "src"
		};
	}

	private static function mergeTemplate(target:Dynamic, source:Dynamic):Void {
		if (target == null || source == null) {
			return;
		}
		for (field in Reflect.fields(source)) {
			Reflect.setField(target, field, Reflect.field(source, field));
		}
	}

	private static function setField(target:Dynamic, name:String, value:Dynamic):Void {
		if (value == null) {
			return;
		}
		if (Std.isOfType(value, String) && cast(value, String).length == 0) {
			return;
		}
		Reflect.setField(target, name, value);
	}

	private static function buildPublishedDependencies(project:ProjectSpec):Dynamic {
		var dependencies:Dynamic = {};
		if (project == null || project.libraries == null) {
			return dependencies;
		}

		for (library in project.libraries) {
			if (library == null || library.name == null || library.name.length == 0) continue;
			if (library.path != null && library.path.length > 0) continue;
			if (isImplicitToolDependency(library.name)) continue;
			Reflect.setField(dependencies, library.name, library.version != null ? library.version : "");
		}

		return dependencies;
	}

	private static function firstNonEmpty(values:Array<String>):String {
		for (value in values) {
			if (value != null && value.length > 0) {
				return value;
			}
		}
		return null;
	}

	private static function resolveClassPath(project:ProjectSpec):String {
		var haxelib = project.haxelib != null ? project.haxelib : null;
		if (haxelib != null && haxelib.classPath != null && haxelib.classPath.length > 0) {
			return haxelib.classPath;
		}
		if (project.sources != null && project.sources.length > 0) {
			return project.sources[0];
		}
		return "src";
	}

	private static function isImplicitToolDependency(name:String):Bool {
		return name != null && name.toLowerCase() == IMPLICIT_TOOL_HAXELIB;
	}

	private static function cloneCapabilities(value:ExtensionCapabilities):Dynamic {
		return {
			description: value != null ? value.description : null,
			defineCatalogs: value != null && value.defineCatalogs != null ? value.defineCatalogs.copy() : [],
			commands: value != null && value.commands != null ? value.commands.copy() : [],
			targets: value != null && value.targets != null ? value.targets.copy() : [],
			profiles: value != null && value.profiles != null ? value.profiles.copy() : []
		};
	}

	private static function appendUnique(target:Array<String>, values:Array<String>):Void {
		for (value in (values != null ? values : [])) {
			if (value == null || value.length == 0 || target.indexOf(value) != -1) continue;
			target.push(value);
		}
	}

	private static function parseSimpleProjectPath(args:Array<String>, startIndex:Int, ?flagOnly:Array<String>):String {
		var simpleFlags = flagOnly != null ? flagOnly : [];
		for (i in startIndex...args.length) {
			var arg = args[i];
			if (simpleFlags.indexOf(arg) != -1) {
				continue;
			}
			if (!StringTools.startsWith(arg, "-")) {
				return resolveUserPath(arg);
			}
		}
		return invocationCwd;
	}

	private static function parseSimpleProjectPathAndJson(args:Array<String>, startIndex:Int):{projectPath:String, json:Bool} {
		var json = false;
		var projectPath = invocationCwd;
		for (i in startIndex...args.length) {
			var arg = args[i];
			if (arg == "-json" || arg == "--json") {
				json = true;
				continue;
			}
			if (!StringTools.startsWith(arg, "-")) {
				projectPath = resolveUserPath(arg);
				continue;
			}
			throw 'Unknown flag: $arg';
		}
		return {projectPath: projectPath, json: json};
	}

	private static function printJson(value:Dynamic):Void {
		Sys.println(JsonPrinter.print(value, null, "\t"));
	}

	private static function programDir():String {
		return Path.directory(Sys.programPath());
	}

	private static function resolveToolHome():String {
		try {
			return ToolEnvironment.getAedifexRoot();
		} catch (_:Dynamic) {
			return programDir();
		}
	}

	private static function resolveUserPath(path:String):String {
		var normalized = Path.removeTrailingSlashes(path);
		if (Path.isAbsolute(normalized)) {
			return Path.normalize(normalized);
		}
		return Path.normalize(Path.join([invocationCwd, normalized]));
	}

	private static function userConfigPath():String {
		var home = Sys.getEnv(#if windows "USERPROFILE" #else "HOME" #end);
		if (home == null || home == "") return null;
		return Path.join([home, USER_CFG_DIR, USER_CFG_FILE]);
	}

	private static function loadUserPluginsPath():Null<String> {
		var path = userConfigPath();
		if (path == null || !FileSystem.exists(path)) return null;
		try {
			var obj:Dynamic = Json.parse(sys.io.File.getContent(path));
			return (obj != null && Reflect.hasField(obj, "pluginsPath")) ? obj.pluginsPath : null;
		} catch (_:Dynamic) {
			return null;
		}
	}

	private static function saveUserPluginsPath(dir:String):Void {
		var cfgPath = userConfigPath();
		if (cfgPath == null) return;
		var cfgDir = Path.directory(cfgPath);
		if (!FileSystem.exists(cfgDir)) FileSystem.createDirectory(cfgDir);
		var obj:Dynamic = {};

		if (FileSystem.exists(cfgPath)) {
			try {
				obj = Json.parse(File.getContent(cfgPath));
			} catch (_:Dynamic) {
				obj = {};
			}
		}
		Reflect.setField(obj, "pluginsPath", dir);
		File.saveContent(cfgPath, JsonPrinter.print(obj, null, "\t"));
	}

	private static function resolvePluginsPath(argv:Array<String>):String {
		for (i in 0...argv.length) {
			var a = argv[i];
			if (a == "-plugins" || a == "--plugins") {
				if (i + 1 < argv.length) {
					var value = argv[i + 1];
					if (value != null && value != "" && !StringTools.startsWith(value, "-")) {
						return resolveUserPath(value);
					}
				}
				continue;
			}
			if (StringTools.startsWith(a, "-plugins=") || StringTools.startsWith(a, "--plugins=")) {
				var prefix = StringTools.startsWith(a, "-plugins=") ? "-plugins=" : "--plugins=";
				var p = a.substr(prefix.length);
				if (p != "") return resolveUserPath(p);
			}
		}
		var env = Sys.getEnv("AEDIFEX_PLUGINS");
		if (env != null && env != "") return resolveUserPath(env);

		var user = loadUserPluginsPath();
		if (user != null && user != "") return resolveUserPath(user);

		return Path.join([resolveToolHome(), "plugins"]);
	}

	private static function help(?args:Array<String>, ?msg:String):Void {
		if (msg != null) Sys.println(msg);
		var showFull = false;
		var showInternals = false;
		if (args != null && args.length > 1) {
			var mode = args[1].toLowerCase();
			showFull = mode == "all" || mode == "full" || mode == "advanced";
			showInternals = mode == "internals" || mode == "internal";
		}
		Sys.println(showInternals ? internalsHelpMessageText : (showFull ? fullHelpMessageText : helpMessageText));
	}

	private static function welcome():Void {
		Sys.println("Aedifex: extensible Haxe build tool");
		Sys.println("");
		Sys.println("Start here:");
		Sys.println("  aedifex build cpp . -debug");
		Sys.println("  aedifex build cpp . -final");
		Sys.println("  aedifex clean cpp . -debug");
		Sys.println("  aedifex run hl .");
		Sys.println("  aedifex create my-app");
		Sys.println("  aedifex rebuild");
		Sys.println("");
		Sys.println("Use `aedifex help` for the quick reference.");
		Sys.println("Use `aedifex help all` for the full command reference.");
		Sys.println("Use `aedifex help internals` for editor/tooling commands.");
	}

	private static inline function ensureDir(p:String):Void {
		if (p == null || p.length == 0 || FileSystem.exists(p)) return;
		var parent = Path.directory(p);
		if (parent != null && parent != "" && parent != p && !FileSystem.exists(parent)) {
			ensureDir(parent);
		}
		FileSystem.createDirectory(p);
	}
}

@:cppInclude("Windows.h")
class ConsoleMode {
	public static function enable():Void {
		#if cpp
		untyped __cpp__('
      #ifdef _WIN32
      #ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
      #define ENABLE_VIRTUAL_TERMINAL_PROCESSING 0x0004
      #endif

      SetConsoleOutputCP(65001);
      SetConsoleCP(65001);

      DWORD m=0; HANDLE h=GetStdHandle(STD_OUTPUT_HANDLE);
      if (h!=INVALID_HANDLE_VALUE && GetConsoleMode(h,&m)) {
        m |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        SetConsoleMode(h,m);
      }
      h=GetStdHandle(STD_ERROR_HANDLE);
      if (h!=INVALID_HANDLE_VALUE && GetConsoleMode(h,&m)) {
        m |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        SetConsoleMode(h,m);
      }
      #endif
    ');
		#end
	}
}

