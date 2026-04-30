# Installation And Deployment

This document describes how Aedifex is installed and how the command is resolved.

## Supported Modes

Aedifex has two normal usage modes:

1. local source checkout
2. haxelib runner

There is still a native build for local development, but the public tool story is runner-first.

## Local Source Checkout

Use this when developing Aedifex itself.

Register the checkout:

```powershell
haxelib dev aedifex C:\path\to\aedifex
```

Build the runner:

```powershell
haxe run.hxml
```

Optional native local build:

```powershell
haxe build.hxml
```

Run directly:

```powershell
neko run.n profiles -json
```

## haxelib Runner

`haxelib run aedifex ...` uses:

- `run.n`

Why:

- it is cross-platform
- it keeps one canonical runtime path
- it matches the active haxelib or `haxelib dev` checkout cleanly

Rebuild the runner:

```powershell
haxe run.hxml
```

## Global `aedifex` Alias

Install the global shim:

```powershell
haxelib run aedifex setup
```

Check it:

```powershell
haxelib run aedifex setup status
```

Remove it:

```powershell
haxelib run aedifex setup remove
```

The shim resolves the active Aedifex install root and invokes the runner from there.

## Tool Root And Project Root

Aedifex keeps two different roots:

- invocation root
- tool root

Invocation root:

- current repo or explicit project path
- where `Aedifex.hx` is loaded from

Tool root:

- installed Aedifex location
- where templates, runner resources, and self-rebuild inputs live

This is how `haxelib run aedifex ...` can operate on the user's project without confusing the haxelib install directory for the project root.

## Rebuild Command

Aedifex can rebuild itself:

```powershell
aedifex rebuild
```

That rebuilds the active runner in the active Aedifex install root.

## Package Layout

The normal haxelib package shape is:

- `src/`
- `template/`
- `docs/`
- `run.n`
- `haxelib.json`

## Plugin Resolution

Plugin lookup order:

1. `-plugins <dir>`
2. `AEDIFEX_PLUGINS`
3. `%USERPROFILE%\.aedifex\config.json`
4. `plugins` under the resolved tool root
