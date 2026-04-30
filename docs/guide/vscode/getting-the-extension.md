# Getting The VS Code Extension

The Aedifex VS Code extension lives in:

- `tools/vscode-extension`

It is designed as a thin editor client over the Aedifex CLI. The build logic still belongs to the CLI; the extension mostly handles editor integration, pickers, tasks, and debug handoff.

## What It Depends On

For `Aedifex.hx` authoring and completion, install:

- `vshaxe`

The Aedifex extension handles project-specific display setup and launch/build orchestration. `vshaxe` still provides the Haxe language service.

## Local Extension Development

Open the extension folder:

```text
tools/vscode-extension
```

Then launch the Extension Development Host from the workspace launcher in:

- `tools/vscode-extension/.vscode/launch.json`

## CLI Resolution Order

The extension resolves the CLI in this order:

1. configured `aedifex.cliPath`
2. local `neko run.n` when the workspace itself is the Aedifex tool checkout
3. installed `aedifex` command
4. `haxelib run aedifex`

That means you can test the extension against:

- the checked-out tool repo
- a regular installed haxelib version
- a custom CLI path when you need to pin something unusual

## Recommended Local Setup

If you are developing Aedifex itself:

```powershell
haxelib dev aedifex /path/to/aedifex
haxe run.hxml
```

Then open the repo and let the extension find the local runner path automatically.

## Next

- [Using the VS Code extension](using-the-extension.md)
- [VS Code extension reference](../../vscode-extension.md)
