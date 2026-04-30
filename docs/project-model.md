# Project Model

This document describes the typed project model authored in `Aedifex.hx`.

## Root Contract

An Aedifex root is:

- `Aedifex.hx`
- in the root package
- `class Aedifex`
- `public static final project:ProjectSpec`

Example:

```haxe
package;

import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.named("Main")
		.source("src")
		.identity("sample-app", "Sample App")
		.version("1.0.0")
		.done();
}
```

## Project Kinds

Supported root kinds:

- `app`
- `library`
- `tool`
- `plugin`
- `extension`

Examples:

- `Project.named("Main")` for a normal app root
- `Project.library("crossbyte")` for a library root
- `Project.tool("aedifex", "Aedifex")` for a tool root

## Main Public Types

- `src/aedifex/build/Project.hx`
- `src/aedifex/build/ProjectSpec.hx`
- `src/aedifex/build/BuildTarget.hx`
- `src/aedifex/build/BuildPlatform.hx`
- `src/aedifex/build/BuildArchitecture.hx`
- `src/aedifex/build/Profile.hx`
- `src/aedifex/build/Define.hx`
- `src/aedifex/build/Defines.hx`
- `src/aedifex/build/BuildCondition.hx`

## `ProjectSpec`

`ProjectSpec` currently includes:

- `kind`
- `meta`
- `haxelib`
- `app`
- `defaultTarget`
- `defaultPlatform`
- `defaultArchitecture`
- `defaultProfile`
- `sources`
- `libraries`
- `defines`
- `haxeflags`
- `hooks`
- `targets`
- `targetRules`
- `extensions`
- `provides`
- `tasks`

## Targets, Qualifiers, And Profiles

Core targets:

- `cpp`
- `hl`
- `neko`
- `js`
- `jvm`
- `php`

Host desktop is implicit for normal desktop targets.

Explicit qualifiers:

- `android`
- `ios`
- `html5`
- `node`

Architectures:

- `x64`
- `x86`
- `arm64`
- `armv7`

Profiles:

- `debug`
- `release`
- `final`

Typical CLI shape:

```powershell
aedifex build cpp . -debug
aedifex build js . -node -release
aedifex build cpp . -android -final
```

## Common Builder Methods

Identity and metadata:

- `named`
- `library`
- `tool`
- `plugin`
- `extension`
- `identity`
- `title`
- `version`
- `company`
- `author`
- `description`
- `url`
- `github`
- `license`
- `releaseNote`
- `tag`
- `tags`
- `contributor`
- `classPath`

Build setup:

- `source`
- `sources`
- `mainClass`
- `defaultTarget`
- `defaultPlatform`
- `defaultArchitecture`
- `defaultProfile`
- `haxelib`
- `library`
- `dependency`
- `define`
- `defineToken`
- `haxeflag`
- `supportsTarget`
- `target`
- `when`
- `hook`

Extensions and exports:

- `use`
- `extend`
- `exportsDefineCatalog`
- `exportsCommand`
- `exportsTarget`
- `exportsProfile`
- `exportsExtension`
- `exportsNamedExtension`

Tasks:

- `task(name, command, args, cwd, description)`

Finish:

- `done`

## Metadata And `haxelib.json`

Aedifex does not need a separate `haxelibPackage(...)` layer to describe package metadata.

Use normal project fields instead:

- `version(...)`
- `description(...)`
- `github(...)`
- `license(...)`
- `tags(...)`
- `author(...)`
- `contributor(...)`
- `classPath(...)`

Then sync or check the packaging artifact:

```powershell
aedifex haxelib sync .
aedifex haxelib check .
```

`haxelib.json` is treated as a synced packaging file built from normal project fields plus a best-effort template.

## Tasks

Roots can expose named workflows:

```haxe
Project
	.tool("my-tool", "My Tool")
	.task("docs", "haxe", ["ci/docs.hxml"], null, "Build docs.")
	.task("smoke", "neko", ["run.n", "help"], null, "Smoke-test the runner.")
	.done();
```

Run them with:

```powershell
aedifex tasks . -json
aedifex task docs .
```

## Conditional Rules

Conditional build rules use `BuildCondition`.

Typical token categories include:

- targets such as `cpp`, `js`, `jvm`
- qualifiers such as `android`, `node`, `html5`
- architectures such as `x64`, `arm64`
- profiles such as `debug`, `release`, `final`

## Hooks

Supported lifecycle phases include:

- `preResolve`
- `postResolve`
- `preBuild`
- `postBuild`
- `preRun`
- `postRun`
- `preFinalize`
- `postFinalize`

## More

- [Defines](defines.md)
- [Extensions](extensions.md)
- [Architecture](architecture.md)
