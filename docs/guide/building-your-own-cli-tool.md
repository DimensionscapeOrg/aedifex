# Building Your Own CLI Tool

Aedifex can be used as the build chassis for a CLI tool repo, not just as the build tool itself.

## Tool Roots

Use `Project.tool(...)` when the repo itself is primarily a tool:

```haxe
package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.tool("my-tool", "My Tool")
		.source("src")
		.mainClass("mytool.cli.Main")
		.version("1.0.0")
		.done();
}
```

Tool roots can still define:

- metadata
- tasks
- setup expectations
- packaging behavior

## Rebuilds

`aedifex rebuild` is reserved for rebuilding the active Aedifex install itself.

Your tool repo should use normal tasks or normal target builds for its own artifacts.

That keeps the command surface simple:

- `build` builds the project
- `rebuild` rebuilds Aedifex itself

## Packaging

For package-style repos, Aedifex can still sync `haxelib.json` from normal project metadata:

```powershell
aedifex haxelib sync .
aedifex haxelib check .
aedifex release package . -validate
```

The idea is to keep `Aedifex.hx` as the source of truth and let packaging artifacts be generated from it when that is helpful.

## Tasks

Tasks are useful for tool repos because they let you expose common workflows without bloating the top-level CLI:

```haxe
Project
	.tool("my-tool", "My Tool")
	.task("docs", "haxe", ["ci/docs.hxml"], null, "Build docs.")
	.task("smoke", "neko", ["run.n", "help"], null, "Smoke-test the runner.")
	.done();
```

Run them with:

```powershell
aedifex task docs .
aedifex task smoke .
```

## When To Extend Further

If you are building something more opinionated on top of Aedifex, such as a framework or a specialized toolchain layer, add that only when it buys you real behavior. The core rule still applies:

- prefer existing Haxe concepts
- keep the surface small
- grow from extension points instead of inventing lots of new nouns

## More

- [Project model reference](../project-model.md)
- [Extensions reference](../extensions.md)
