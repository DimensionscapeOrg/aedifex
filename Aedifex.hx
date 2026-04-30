package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.tool("aedifex", "Aedifex")
		.github("dimensionscapeorg/aedifex")
		.license("GPL")
		.tags(["haxe", "build", "tool", "cli", "automation"])
		.description("Haxe build tool with typed Aedifex.hx project roots, library metadata sync, task automation, and extension support.")
		.version("1.0.0-rc.3")
		.releaseNote("Third release candidate with target setup readiness, runner-first packaging, curated documentation, stronger API hinting, and a refined VS Code workflow.")
		.contributor("Dimensionscape")
		.source("src")
		.mainClass("aedifex.cli.Main")
		.task("rebuild-native", "haxe", ["build.hxml"], null, "Rebuild the native Aedifex executable.")
		.task("rebuild-runner", "haxe", ["run.hxml"], null, "Rebuild the Neko haxelib runner.")
		.task("rebuild-extension", "neko", ["run.n", "extension"], null, "Package the VS Code extension as a pre-release VSIX.")
		.task("docs-validate", "haxe", ["ci/docs-validate.hxml"], null, "Validate markdown links and docs structure.")
		.task("docs-api", "haxe", ["ci/docs-api.hxml"], null, "Generate curated Dox API documentation.")
		.task("docs", "haxe", ["ci/docs.hxml"], null, "Validate docs and build the docs artifact.")
		.done();
}
