# Building Apps

App roots use `Aedifex.hx` plus one or more source paths to describe how a Haxe application should be built.

## Minimal App Root

```haxe
package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.named("Main")
		.source("src")
		.identity("hello-world", "Hello World")
		.version("1.0.0")
		.done();
}
```

## Targets

Core targets:

- `cpp`
- `hl`
- `neko`
- `js`
- `jvm`
- `php`

Desktop host information is implicit. If you run `aedifex build cpp` on Windows, that means a Windows desktop cpp build. If you run the same command on macOS or Linux, it means the host desktop for that machine.

## Qualifiers

Only explicit environment qualifiers stay in the public CLI:

- `-android`
- `-ios`
- `-html5`
- `-node`

Examples:

```powershell
aedifex build cpp . -android -release
aedifex build js . -node -debug
aedifex build js . -html5 -final
```

## Profiles

Profiles shape the build mode:

- `-debug`
- `-release`
- `-final`

Profile output is stored in separate caches, so `debug`, `release`, and `final` do not trample each other.

## Build, Run, Test, And Clean

Build:

```powershell
aedifex build cpp . -debug
```

Run:

```powershell
aedifex run cpp . -debug
```

Test:

```powershell
aedifex test neko . -debug
```

Clean without building:

```powershell
aedifex clean cpp . -release
```

Clean-build:

```powershell
aedifex build cpp . -clean -release
```

## Readiness Prompts And `-ignore`

Before `build`, `run`, or `test`, Aedifex checks whether the requested target environment is ready.

If the target is not ready:

- interactive terminal: Aedifex asks whether to run `setup`
- non-interactive usage: Aedifex fails with the exact setup command to run
- `-ignore`: skip prompts and fail cleanly

That keeps the everyday workflow friendly without making CI ambiguous.

## Machine-Readable Inspection

These commands are useful for tooling and debugging:

```powershell
aedifex explain . -json
aedifex targets . -json
aedifex build-plan cpp . -release -json
aedifex launch-plan js . -node -debug -json
```

## More

- [Project model reference](../project-model.md)
- [Architecture reference](../architecture.md)
- [Using the VS Code extension](vscode/using-the-extension.md)
