package aedifex.core;

import aedifex.build.BuildArchitecture;
import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.build.Profile;
import aedifex.build.ProjectSpec;
import aedifex.build.ProjectSpec.BuildPhase;
import aedifex.build.internal.ExecutionPlanner;

class Runner {
	public static function run(
		project:ProjectSpec,
		target:BuildTarget,
		platform:BuildPlatform,
		architecture:BuildArchitecture,
		profile:Profile,
		projectRoot:String
	):Void {
		var launchPlan = ExecutionPlanner.launchPlan(projectRoot, project, target, platform, architecture, profile);
		if (!launchPlan.runSupported) {
			throw launchPlan.constraints.reason != null ? launchPlan.constraints.reason : 'Target `${target}` is not runnable on this host.';
		}

		var resolvedProject:ProjectSpec = cast ExecutionPlanner.buildPlan(projectRoot, project, target, platform, architecture, profile).project;
		Builder.runHooks(resolvedProject.hooks, BuildPhase.PRE_RUN, projectRoot);

		var launcher:Dynamic = launchPlan.launcher;
		var cmd = new Command();
		if (launcher.command == null) {
			throw 'No launcher command is available for target `${target}`.';
		}

		cmd.add(launcher.command);
		cmd.addMany(launcher.args != null ? cast launcher.args : []);

		var previous = Sys.getCwd();
		var failure:Dynamic = null;
		try {
			Sys.setCwd(launcher.cwd != null ? launcher.cwd : projectRoot);
			var code = cmd.run();
			if (code != 0) {
				failure = "run failed with exit " + code;
			}
		} catch (e:Dynamic) {
			failure = e;
		}
		Sys.setCwd(previous);
		if (failure != null) {
			throw failure;
		}

		Builder.runHooks(resolvedProject.hooks, BuildPhase.POST_RUN, projectRoot);
	}
}
