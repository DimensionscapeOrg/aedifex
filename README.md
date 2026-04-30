# Aedifex

Aedifex is a Haxe build tool that uses a root `Aedifex.hx` file instead of `hxml` as the main authored project definition.

## What It Does

- defines a project with `Aedifex.hx`
- builds and runs apps by Haxe target plus optional platform and arch flags
- supports library/framework roots as well as app roots
- syncs or exports `haxelib.json` from `Aedifex.hx` for library-style repos
- exposes machine-readable CLI output for tools such as the VS Code extension

## Install

Local dev checkout:

```powershell
haxelib dev aedifex /path/to/aedifex
haxe build.hxml
haxe run.hxml
```

Install a global `aedifex` command next to `haxe.exe`:

```powershell
haxelib run aedifex setup
```

More details:

- [Installation And Deployment](docs/installation-and-deployment.md)

## Project Root

An Aedifex-managed repo has a root [Aedifex.hx](template/haxe/Aedifex.hx) with:

- root package
- `class Aedifex`
- `public static final project:ProjectSpec`

Minimal app root:

```haxe
package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.named("Main")
		.source("src")
		.identity("my-app", "My App")
		.version("1.0.0")
		.done();
}
```

Minimal library root:

```haxe
package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.library("my-lib")
		.source("src")
		.version("1.0.0")
		.github("you/my-lib")
		.license("MIT")
		.done();
}
```

More details:

- [Project Model](docs/project-model.md)

## Create A Project

Create an app:

```powershell
aedifex create path/to/MyApp
```

Create a library/framework root:

```powershell
aedifex create path/to/MyLib --library
```

Generated files:

- `Aedifex.hx`
- `ProjectDefines.hx`
- `src/Main.hx` for app roots

## Example Project

A small runnable sample lives at [examples/hello-world](examples/hello-world).
Its local usage note is at [examples/hello-world/README.md](examples/hello-world/README.md).

Build it with Neko:

```powershell
aedifex build neko examples/hello-world -debug
aedifex run neko examples/hello-world -debug
```

Or build it for Node:

```powershell
aedifex build js examples/hello-world -node -debug
```

## Targets, Platforms, And Profiles

Core targets:

- `cpp`
- `hl`
- `neko`
- `js`
- `jvm`
- `php`

Platform/runtime qualifiers:

- `-windows`
- `-mac`
- `-linux`
- `-android`
- `-ios`
- `-html5`
- `-node`

Architectures:

- `-x64` by default
- `-x86`
- `-arm64`
- `-armv7`

Profiles:

- `debug`
- `release`
- `final`

## Common Commands

Inspect a project:

```powershell
aedifex explain . --json
aedifex targets . --json
aedifex profiles --json
```

Build and run an app:

```powershell
aedifex build cpp . -debug
aedifex run cpp . -debug
```

Build for a qualified target:

```powershell
aedifex build cpp . -android -release
aedifex build js . -node -debug
aedifex build js . -html5 -final
```

Manage library tasks and package metadata:

```powershell
aedifex tasks . --json
aedifex task interp-tests .
aedifex haxelib sync .
aedifex haxelib check .
```

`aedifex haxelib sync .` updates `haxelib.json` from the metadata declared in `Aedifex.hx`.

`aedifex haxelib check .` verifies that the checked-in `haxelib.json` still matches what Aedifex would sync.

Library and framework roots do not need a build step just to publish package metadata. Treat `Aedifex.hx` as the source of truth and `haxelib.json` as a synced packaging artifact built from normal project fields plus a best-effort template.

Package a haxelib release:

```powershell
aedifex release package . --validate
```

## Full CLI

```text
aedifex create <path> [--plugin] [--library]
aedifex build <target> <projectPath> [-windows|-mac|-linux|-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final] [--define KEY[=VAL]]... [--lib LIB]... [--plugins=<dir>]
aedifex clean <target> <projectPath> [-windows|-mac|-linux|-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final] [--define KEY[=VAL]]... [--lib LIB]... [--plugins=<dir>]
aedifex run <target> <projectPath> [-windows|-mac|-linux|-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final] [--plugins=<dir>]
aedifex test <target> <projectPath> [-windows|-mac|-linux|-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final] [--plugins=<dir>]
aedifex rebuild
aedifex setup [status|remove]
```

Use `aedifex help all` for the complete command reference, including introspection, packaging, and plugin-management commands.

## Rebuilding Aedifex

```powershell
aedifex rebuild
```

Use `aedifex build <target> ... -final` when you want final-profile output and finalization hooks.

- `rebuild` rebuilds [run.hxml](run.hxml) in the active Aedifex install root
- the global shims always invoke [run.n](run.n)

## VS Code

The VS Code extension lives in `tools/vscode-extension`.

It currently:

- activates on `Aedifex.hx`
- shows a target chooser
- shows a profile chooser
- provides one Aedifex debug flow backed by `launch-plan`

More details:

- [VS Code Extension](docs/vscode-extension.md)

## More Docs

- [Project Model](docs/project-model.md)
- [Defines](docs/defines.md)
- [Extensions](docs/extensions.md)
- [Architecture](docs/architecture.md)
- [Installation And Deployment](docs/installation-and-deployment.md)
