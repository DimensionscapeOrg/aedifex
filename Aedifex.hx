package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.tool("aedifex", "Aedifex")
		.github("dimensionscape-llc/aedifex")
		.license("GPL")
		.tags(["haxe", "build", "tool", "cli", "automation"])
		.description("Haxe build tool with typed Aedifex.hx project roots, library metadata sync, task automation, and extension support.")
		.version("1.0.0-rc.2")
		.releaseNote("Second release candidate of the Aedifex.hx-based chassis with target-based commands, library roots, task support, haxelib metadata sync, typed define catalogs, and VS Code extension scaffolding.")
		.contributor("Dimensionscape")
		.haxelib("hxcpp")
		.source("src")
		.mainClass("aedifex.cli.Main")
		.task("rebuild-native", "haxe", ["build.hxml"], null, "Rebuild the native Aedifex executable.")
		.task("rebuild-runner", "haxe", ["run.hxml"], null, "Rebuild the Neko haxelib runner.")
		.task("docs-validate", "haxe", ["ci/docs-validate.hxml"], null, "Validate markdown links and docs structure.")
		.task("docs-api", "haxe", ["ci/docs-api.hxml"], null, "Generate curated Dox API documentation.")
		.task("docs", "haxe", ["ci/docs.hxml"], null, "Validate docs and build the docs artifact.")
		.done();
}
