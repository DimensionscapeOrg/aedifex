# Getting Started

Aedifex is a Haxe build tool that treats `Aedifex.hx` as the authored project root.

Instead of leading with a top-level `hxml`, you define your project in Haxe and let Aedifex resolve targets, qualifiers, profiles, setup readiness, tasks, and packaging from there.

## Install

Packaged install:

```powershell
haxelib install aedifex
haxelib run aedifex setup
```

Local development checkout:

```powershell
haxelib dev aedifex /path/to/aedifex
haxe build.hxml
haxe run.hxml
```

That gives you a global `aedifex` shim that resolves the active haxelib checkout and runs the runner from there.

## Create Your First Project

App root:

```powershell
aedifex create path/to/MyApp
```

Library root:

```powershell
aedifex create path/to/MyLib -library
```

Plugin root:

```powershell
aedifex create path/to/MyPlugin -plugin
```

## Set Up A Target

Before building a target for the first time, use `setup` to make sure the toolchain is ready:

```powershell
aedifex setup cpp
aedifex setup neko
aedifex setup js -node
```

Helpful modes:

```powershell
aedifex setup cpp -check
aedifex setup js -node -json
```

`setup` is environment-only. It is about preparing the current machine, not mutating a project.

## First Build And Run

Native desktop build for the current host:

```powershell
aedifex build cpp . -debug
aedifex run cpp . -debug
```

Node build:

```powershell
aedifex build js . -node -debug
aedifex run js . -node -debug
```

If the selected target is not ready and you are in an interactive terminal, Aedifex will ask whether you want to run setup first. Use `-ignore` when you want it to fail cleanly instead of prompting.

## What To Read Next

- [Building apps](building-apps.md)
- [Getting the VS Code extension](vscode/getting-the-extension.md)
- [Using the VS Code extension](vscode/using-the-extension.md)
- [Project model reference](../project-model.md)
