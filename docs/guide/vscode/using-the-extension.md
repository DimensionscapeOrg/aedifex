# Using The VS Code Extension

The extension is meant to feel like one Aedifex-powered build surface, not a pile of unrelated debug entries.

## What You Get

- a target picker in the status bar
- a profile picker in the status bar
- a small `Clean` button in the status bar
- one `Aedifex` task
- one `Aedifex` launch/debug entry

## Build, Run, And Debug

Normal editor flow:

1. choose a target
2. choose a profile
3. optionally hit `Clean`
4. use `Aedifex: Build`, `Aedifex: Run`, or `F5`

`F5` means “launch with the current Aedifex selection.”

If the selected target supports real VS Code debugging, the extension builds first and then starts a debugger-backed session.

If the target is runnable but does not currently expose a real VS Code debugger, `F5` builds first and then runs normally instead of pretending there is a debugger.

## Terminal Vs Output

The intended split is:

- **Terminal**
  - user-visible work such as build, run, clean, rebuild, and named task execution
- **Output**
  - extension internals such as refresh, display sync, `explain`, `targets`, and `launch-plan` queries

So if you click something visible, you should expect to see a terminal-backed flow.

## Non-App Roots

The extension still activates for:

- libraries
- tools
- plugins
- extensions

But it avoids inventing a fake default runnable target for those roots.

Examples:

- a tool root can rebuild itself
- a library root can still expose tasks and metadata
- an app root gets the full build/run/debug flow

## `Aedifex.hx` Completion

`Aedifex.hx` lives at the repo root, often outside `src/`, so the extension prepares a display context for `vshaxe` instead of requiring you to maintain a hand-written top-level `hxml`.

That is why Aedifex project authoring can still work cleanly without a visible root build file.

## Settings

Common settings:

- `aedifex.cliPath`
- `aedifex.pluginsPath`
- `aedifex.theme`

## More

- [Getting the extension](getting-the-extension.md)
- [VS Code extension reference](../../vscode-extension.md)
