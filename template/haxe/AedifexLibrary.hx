package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.library("default-library")
		.source("src")
		.version("1.0.0")
		// .github("you/default-library")
		// .license("MIT")
		// .haxelib("lime")
		// .exportsDefineCatalog("ProjectDefines")
		.done();
}
