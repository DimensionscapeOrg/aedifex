# VS Code Extension Reference

The VS Code extension is a thin client over the Aedifex CLI.

Main files:

- `tools/vscode-extension/package.json`
- `tools/vscode-extension/extension.js`

## What It Does

- activates when a workspace contains `Aedifex.hx`
- shows a target status bar item
- shows a profile status bar item
- shows a `Clean` status bar item
- provides `Aedifex: Build`
- provides `Aedifex: Run`
- provides `Aedifex: Debug`
- provides one `Aedifex` launch/debug identity
- uses `launch-plan -json` to drive launch/debug resolution

For roots with no runnable target, the extension still activates, but it does not invent a fake app flow.

## Commands Used

The extension depends on CLI commands such as:

- `aedifex explain . -json`
- `aedifex targets . -json`
- `aedifex profiles -json`
- `aedifex build ...`
- `aedifex launch-plan ... -json`

## CLI Resolution

The extension resolves the CLI in this order:

1. configured `aedifex.cliPath`
2. local `neko run.n` when the workspace is the Aedifex tool checkout
3. installed `aedifex` command
4. `haxelib run aedifex`

## Debug Behavior

Debug flow:

1. read the current target and profile
2. build first
3. read `launch-plan -json`
4. convert the launch plan into a VS Code launch/debug action

Native launchers use:

- `cppvsdbg` on Windows
- `cppdbg` on non-Windows native targets

Terminal-style launchers stay in VS Code's integrated terminal flow when appropriate.

## Settings

- `aedifex.cliPath`
- `aedifex.pluginsPath`
- `aedifex.theme`

## Local Testing

Open:

- `tools/vscode-extension`

Then launch the Extension Development Host from:

- `tools/vscode-extension/.vscode/launch.json`

If you are developing Aedifex itself, register the local repo with `haxelib dev aedifex ...` and let the extension resolve the local runner path automatically.

## More

- [Getting the extension](guide/vscode/getting-the-extension.md)
- [Using the extension](guide/vscode/using-the-extension.md)
