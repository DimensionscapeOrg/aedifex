# Aedifex

Aedifex is a Haxe build tool built around a typed `Aedifex.hx` project root instead of a hand-authored top-level `hxml`.

The public surface stays intentionally small:

- target-first build commands
- environment setup as a first-class contract
- Haxe-authored project metadata
- task automation
- machine-readable tooling for editor integration

## Quick Start

Install:

```powershell
haxelib install aedifex
haxelib run aedifex setup
```

Local development checkout:

```powershell
haxelib dev aedifex /path/to/aedifex
haxe run.hxml
```

Create an application:

```powershell
aedifex create path/to/MyApp
```

Prepare a target and build:

```powershell
aedifex setup cpp
aedifex build cpp path/to/MyApp -debug
aedifex run cpp path/to/MyApp -debug
```

## Minimal Application Example

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

## Minimal Library Or Tool Example

Library root:

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

Tool root:

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

## Command Reference

```text
aedifex create <path> [-plugin] [-library]
aedifex build <target> [projectPath] [-clean] [-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final] [-ignore]
aedifex clean <target> [projectPath] [-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final]
aedifex run <target> [projectPath] [-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final] [-ignore]
aedifex test <target> [projectPath] [-android|-ios|-html5|-node] [-x64|-x86|-arm64|-armv7] [-debug|-release|-final] [-ignore]
aedifex setup [status|remove]
aedifex setup <target> [-android|-ios|-html5|-node] [-check] [-json]
aedifex rebuild
```

Global convenience flags:

- `-theme aurora`
- `-theme`
- `-plugins path/to/plugins`

## Targets, Qualifiers, And Profiles

Core targets:

- `cpp`
- `hl`
- `neko`
- `js`
- `jvm`
- `php`

Explicit qualifiers:

- `-android`
- `-ios`
- `-html5`
- `-node`

Profiles:

- `-debug`
- `-release`
- `-final`

Host desktop is implicit. `aedifex build cpp` means the current machine's desktop cpp target.

## Setup And Readiness

Use `setup` to make the current machine ready for a target:

```powershell
aedifex setup cpp
aedifex setup hl
aedifex setup neko
aedifex setup jvm
aedifex setup php
aedifex setup js
aedifex setup js -node
```

Helpful modes:

```powershell
aedifex setup cpp -check
aedifex setup js -node -json
```

If you try to `build`, `run`, or `test` a target that is not ready:

- interactive terminals can offer to run setup first
- `-ignore` skips the question and fails cleanly

## Example Project

A small runnable sample lives at [examples/hello-world](examples/hello-world).

Try:

```powershell
aedifex build neko examples/hello-world -debug
aedifex run neko examples/hello-world -debug
aedifex build js examples/hello-world -node -debug
```

## Documentation

Guides:

- [Guide index](docs/guide/README.md)
- [Getting started](docs/guide/getting-started.md)
- [Building apps](docs/guide/building-apps.md)
- [Getting the VS Code extension](docs/guide/vscode/getting-the-extension.md)
- [Using the VS Code extension](docs/guide/vscode/using-the-extension.md)
- [Building plugins](docs/guide/building-plugins.md)
- [Building your own CLI tool](docs/guide/building-your-own-cli-tool.md)

Reference:

- [Project model](docs/project-model.md)
- [Extensions](docs/extensions.md)
- [Defines](docs/defines.md)
- [Architecture](docs/architecture.md)
- [Installation and deployment](docs/installation-and-deployment.md)
- [VS Code extension reference](docs/vscode-extension.md)

API reference:

- Build the curated API reference locally with `aedifex task docs-api .`
- Build the full documentation artifact with `aedifex task docs .`
- CI uploads the generated documentation artifact for each successful docs job

Build docs locally:

```powershell
aedifex task docs .
```

Or build only the curated API docs:

```powershell
aedifex task docs-api .
```

## VS Code

The extension lives in `tools/vscode-extension`.

At a glance:

- target picker
- profile picker
- clean button
- one `Aedifex` task
- one `Aedifex` launcher/debug identity

See:

- [Getting the extension](docs/guide/vscode/getting-the-extension.md)
- [Using the extension](docs/guide/vscode/using-the-extension.md)
