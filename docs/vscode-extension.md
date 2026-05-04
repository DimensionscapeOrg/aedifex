# VS Code Extension Reference

The VS Code extension is a thin client over the Aedifex CLI.

Main files:

- `tools/vscode-extension/package.json`
- `tools/vscode-extension/extension.js`

Local plugin surface:

- workspace plugin manifests under `.aedifex/plugins/*.json`

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
- prefers workspace plugin target manifests when present so plugins can provide custom picker entries such as `html5` or `windows`

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

## Workspace Plugin Manifests

The VS Code extension can be extended by local Aedifex plugins without publishing a separate VS Code extension.

If a workspace contains `.aedifex/plugins/*.json`, the extension reads any `targets` declared there and uses them for the target picker, build/run/debug flows, and generated `.vscode/launch.json` and `.vscode/tasks.json`.

Minimal example:

```json
{
  "name": "lime",
  "targets": [
    {
      "name": "html5",
      "target": "js",
      "platform": "html5",
      "backend": "lime"
    },
    {
      "name": "windows",
      "target": "cpp",
      "platform": "windows",
      "backend": "lime"
    }
  ]
}
```

Supported target fields:

- `name` or `label`: picker label shown in VS Code
- `target`: underlying Aedifex target token such as `js` or `cpp`
- `platform`: optional platform qualifier such as `html5`, `windows`, or `nodejs`
- `architecture`: optional architecture qualifier
- `backend`: optional description label
- `buildSupported`, `runSupported`, `hidden`, `reason`: optional UI metadata

## Local Testing

Open:

- `tools/vscode-extension`

Then launch the Extension Development Host from:

- `tools/vscode-extension/.vscode/launch.json`

If you are developing Aedifex itself, register the local repo with `haxelib dev aedifex ...` and let the extension resolve the local runner path automatically.

## More

- [Getting the extension](guide/vscode/getting-the-extension.md)
- [Using the extension](guide/vscode/using-the-extension.md)
