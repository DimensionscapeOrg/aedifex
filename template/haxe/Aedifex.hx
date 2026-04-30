package;

import aedifex.build.BuildCondition;
import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.named("Main")
		.source("src")
		.identity("DefaultApplication", "DefaultApplication")
		.version("1.0.0")
		.when(BuildCondition.when(ProjectDefines.DEBUG), function(target) {
			target.defineToken(ProjectDefines.DEBUG);
		})
		// .defineToken(ProjectDefines.TELEMETRY)
		.done();
}
