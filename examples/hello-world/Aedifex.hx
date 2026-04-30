package;

import aedifex.build.BuildCondition;
import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;
import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.named("Main")
		.source("src")
		.identity("hello-world", "Hello World")
		.version("1.0.0")
		.description("Tiny runnable sample project for Aedifex smoke testing.")
		.defaultTarget(BuildTarget.NEKO)
		.defaultPlatform(BuildPlatform.hostNative())
		.when(BuildCondition.when(ProjectDefines.DEBUG), function(target) {
			target.defineToken(ProjectDefines.DEBUG);
		})
		.done();
}
